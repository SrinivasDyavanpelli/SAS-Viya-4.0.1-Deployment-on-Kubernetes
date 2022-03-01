![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Updating in Place

Broad steps:

Core steps:

* Deploy a normal 2020.0.4
* Get deployment assets for 2020.0.5
* Replace `sas_bases`
* Rebuild site.yaml (with kustomize)
* Apply new site.yaml

doc: <http://pubshelpcenter.unx.sas.com:8080/test/?cdcId=itopscdc&cdcVersion=v_005&docsetId=k8sag&docsetTarget=p0hm2t63wm8qcqn1iqs6y8vw8y81.htm&locale=en>

Flavor-of-the-month Steps

* random things to do
* Either "pre-apply" or "post-apply"
* Change with each release
* may not apply to you

doc: <http://pubshelpcenter.unx.sas.com:8080/test/?cdcId=itopscdc&cdcVersion=v_005&docsetId=dplynotes&docsetTarget=n1ioc0937v7hdvn1xiufnlzq62r8.htm&locale=en#>

## Book Blank collection

* [Book D1](http://race.exnet.sas.com/Reservations?action=new&imageId=291499&imageKind=C&comment=Viya4%20-%20Shared%20coll_%20Shared%20coll&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0) the shared collection

* deploy gelenv 2020.0.4

    ```bash
    #deploy gelenv for 2020.0.4

    cd ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/
    git pull
    git reset --hard origin/master
    bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.02.CreateCheatcodes.sh start

    # Override with a prior version
    export CADENCE_VERSION=2020.0.4
    bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/01_Introduction/01_000_gelenv_order.sh

    gel_OKViya4 -n gelenv-stable --wait -ps

    cd ~/project/deploy/gelenv-stable/
    git init

    git config --global user.email "erwan.granger@sas.com"
    git config --global user.name "Erwan Granger"

    git add .
    git commit -m "commit while at 2020.0.4"


    ```



* Scale all to 2 replicas

```bash
ansible localhost \
    -m lineinfile \
    -a  "dest=~/project/deploy/gelenv-stable/kustomization.yaml \
        insertafter='^transformers:' \
        line='  #- sas-bases/overlays/scaling/ha/enable-ha-transformer.yaml' \
        state=present \
        backup=yes " \
        --diff

kustomize build -o site.yaml
git add .
git commit -m "enable HA for stateless"

# never mind that did not exist at 2020.0.4
# instead:
kubectl -n gelenv-stable scale deploy sas-logon-app --replicas=2
```

* prep UIP

    ```bash

    cp ~/payload/orders/*9CDZDD*stable_2020.0.5*.tgz ~/project/deploy/gelenv-stable/

    cd ~/project/deploy/gelenv-stable/


    rm -rf ~/project/deploy/gelenv-stable/sas-bases/

    tar xf *9CDZDD*stable_2020.0.5*.tgz

    git add .
    git commit -m "updated sas_bases to 2020.0.5"

    kustomize build -o site.yaml

    git add .
    git commit -m "re-built site.yaml"

    ```

To change the logging level.

* In EV.
* Configuration > Definitions > Logging Level.
* New Configuration > Service "SAS Logon Manager" > level "TRACE"
* name: "com.sas.logon".
* That will get you everything logon can produce.
* I wouldn't keep it set at TRACE for too long  Not sure about the version question.

(where this ends up in consul: config/application/logging.level/com.sas.logon=TRACE    )

```bash
curl -s  http://gelenv-stable.$(hostname -f)/SASLogon/apiMeta/build/

for (( ; ; ))
do
    curl -s  http://gelenv-stable.$(hostname -f)/SASLogon/apiMeta/build/
    echo
    sleep 1
done

kubectl -n gelenv-stable delete hpa sas-logon-app
kubectl -n gelenv-stable  autoscale deployment sas-logon-app --max 6 --min 4
watch 'kubectl get pods -n gelenv-stable | grep logon '

stern -n gelenv-stable sas-logon --since 10s

watch "kubectl -n gelenv-stable get hpa | grep -E 'NAME|logon' "

for (( ; ; )); do  date ; curl -s  http://gelenv-stable.$(hostname -f)/SASLogon/apiMeta/build/ | grep 'buildVersion\"\:\".*\"' ; sleep 1  ; done

for (( ; ; )); do  date ; curl -s  http://gelenv-stable.$(hostname -f)/SASLogon/apiMeta/build/ | jq '.buildVersion'  ; sleep 1  ; done

```



* now do the UIP steps

* pre steps

```bash
kubectl -n gelenv-stable delete  statefulSet sas-cacheserver
kubectl -n gelenv-stable delete pvc cacheserver-sas-cacheserver-0

kubectl apply -f sas-bases/overlays/internal-postgres/postgres-cluster-update/pgtask-rmdata.yaml -n gelenv-stable
kubectl get po -l pg-cluster=sas-crunchy-data-postgres -n gelenv-stable
kubectl scale deployment --replicas=0 sas-crunchy-data-postgres-operator -n gelenv-stable

kubectl get po -l vendor=crunchydata,pgrmdata!=true,name!=sas-crunchy-data-pgadmin -n gelenv-stable

```




* actual apply

```bash

cd ~/project/deploy/gelenv-stable/
# single step apply
# kubectl -n gelenv-stable apply -f site.yaml

# 3-step apply
NS=gelenv-stable

kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml
kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd
kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune
kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune

kubectl  -n ${NS} apply -f site.yaml


```


```bash
# and maybe
kubectl -n gelenv-stable delete pods -l app.kubernetes.io/managed-by=sas-cas-operator

kubectl -n gelenv-stable get po --sort-by=.status.startTime

```

kubectl -n gelenv-stable delete pods -l app.kubernetes.io/managed-by=sas-cas-operator




## get a new deployment asset (hotfix level)

```bash
cp -R $HOME/payload/viya4ordercli $HOME

#first let's install go
sudo yum install go -y
go version
# build the go executable
# github path
#cd viya4-orders-cli/
# playload path
cd $HOME/viya4ordercli
go build main.go

echo -n "555555555" | base64 > /tmp/clientid.txt
echo -n "555555555" | base64 > /tmp/secret.txt
echo "clientCredentialsId= "\"$(cat /tmp/clientid.txt)\" > $HOME/.viya4-orders-cli.env
echo "clientCredentialsSecret= "\"$(cat /tmp/secret.txt)\" >> $HOME/.viya4-orders-cli.env

cd $HOME/viya4ordercli

go run main.go -c $HOME/.viya4-orders-cli.env dep 9CDZDD stable 2020.0.5

cp /home/cloud-user/viya4ordercli/SASViyaV4_9CDZDD_0_stable_2020.0.5_20200924.1600985745738_deploymentAssets_2020-09-30T173109.tgz \
    ~/project/deploy/gelenv-stable
cd ~/project/deploy/gelenv-stable


cd $HOME/viya4-orders-cli
docker build . -t viya4-orders-cli

docker run viya4-orders-cli viya4-orders-cli deploymentAssets --help

docker container run \
    --rm \
    -v $HOME/.viya4-orders-cli.env:/tmp/.viya4-orders-cli.env \
    viya4-orders-cli \
     viya4-orders-cli -c /tmp/.viya4-orders-cli.env \
         deploymentAssets 9CDZDD 2020.0.5

```

kubectl -n gelenv-stable rollout restart  deployments  sas-files
