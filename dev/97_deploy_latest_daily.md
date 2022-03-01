![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)


# Deploy Minimal Environment

* [Cleaning for a failed attempt](#cleaning-for-a-failed-attempt)
* [prep the files](#prep-the-files)
* [create a namespace, and make it the default one](#create-a-namespace-and-make-it-the-default-one)
* [Deploy the GELLDAP into the testready namespace](#deploy-the-gelldap-into-the-testready-namespace)
* [Create patch file to lower CPU requests down to 10m](#create-patch-file-to-lower-cpu-requests-down-to-10m)
* [Create transformer to mount the sssd.conf file from the configmap content](#create-transformer-to-mount-the-sssdconf-file-from-the-configmap-content)
* [adding the token](#adding-the-token)
* [Kustomization steps](#kustomization-steps)

<!--
    ```bash

    undo_it () {

    if kubectl get ns | grep -q 'testready\ '
    then
        kubectl -n testready delete deployments --all --force --grace-period=0
        kubectl -n testready delete services --all --force --grace-period=0
        kubectl -n testready delete pods --all --force --grace-period=0
        kubectl -n testready delete ing --all --force --grace-period=0
        kubectl -n testready delete all --all --force --grace-period=0
        kubectl -n testready delete pvc --all --force --grace-period=0
        #kubectl delete ns testready

        hollow_out_ns () {
            if  [ "$1" == "" ]; then
                printf "Please add a namespace\nExiting\n"
            else
                items_to_delete=$(kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed -e 's/,$//')
                # printf "\nHere are all the deleteable, namespaced resources:\n\n$items_to_delete\n"
                printf "\n The delete command would therefore be:\n--------\n kubectl -n $1 delete --all $items_to_delete \n------\n"
                kubectl -n $1 delete --all $items_to_delete --grace-period 0 --force
            fi
        }

    fi

    }

    if  [ "$1" == "wipeclean" ]; then
        #undo_it
        #hollow_out_ns testready
        if kubectl get ns | grep -q 'testready\ '
        then
            #kubectl -n testready delete all,ing,events,pvc --all
            time kubectl delete ns testready
        fi
    fi



    if  [ "$1" == "reset" ]; then
        exit
    fi

    ```
 -->

## Cleaning for a failed attempt

1. Empty out the namespace

    ```sh

    if kubectl get ns | grep -q 'testready\ '
    then
        kubectl -n testready delete all,ing,events,pvc --all
        kubectl delete ns testready
    fi

    ```

## prep the files

1. create a working dir

    ```bash
    #rm -rf ~/project/deploy/testready/
    rm -rf ~/project/deploy/testready/*
    mkdir -p ~/project/deploy/testready/site-config/
    ```

1. Get the .tgz  (this will have to change ...)

    ```bash
    ## most recent order

    cp /tmp/testready_kustomize.tgz ~/project/deploy/testready/
    cd ~/project/deploy/testready/
    tar xvf testready_kustomize.tgz

    ls -altr

    ```

1. do the first commit (.tgz)

    ```bash
    cd ~/project/deploy/testready/

    my_name=erwan-granger

    git init
    git config --local user.email "$my_name@ItDoesNotMatter.com"
    git config --local user.name "$my_name"


    git add kustomize.tgz
    git commit -m " adding the .tgz file, just because"

    ```

1. explode the .tar file

    ```bash
    cd ~/project/deploy/testready/

    ```

1. Now add all the content of the tar to Git

    ```bash
    cd ~/project/deploy/testready/
    git add *
    git commit -m "exploded .tgz. this is the result"

    ```

## create a namespace, and make it the default one

1. Create a namespace for Viya 4

    ```bash
    tee  ~/project/deploy/testready/namespace.yaml > /dev/null << "EOF"
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: testready
      labels:
        name: "testready"
    EOF

    kubectl apply -f ~/project/deploy/testready/namespace.yaml
    kubectl get ns

    ```

1. let's choose to work in the testready namespace by default

    ```sh
    kubectl config set-context --current --namespace testready

    ```

## Deploy the GELLDAP into the testready namespace

1. Clone the GELLDAP project into the project directory

    ```bash
    cd ~/project/
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/project/gelldap/
    git fetch --all
    git reset --hard origin/master

    ```

1. Deploy GELLDAP into the namespace (** do provide the namespace here **)

    ```bash
    cd ~/project/gelldap/
    kustomize build ./no_TLS/ | kubectl -n testready apply -f -

    ```

1. Let's copy the provided file in the proper location:

    ```bash
    cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
       ~/project/deploy/testready/site-config/

    ```

## Create patch file to lower CPU requests down to 10m

1. lower cpu for everything

    ```bash
    ## david method
    bash -c "cat << EOF > ~/project/deploy/testready/site-config/cpu_requests_lowerer.yaml
    - op: add
      path: /spec/template/spec/containers/0/resources/requests/cpu
      value: "10m"
    EOF"
    ```

## Create transformer to mount the sssd.conf file from the configmap content

1. That ConfigMap needs to be added into the right location inside the CAS pod(s):

    ```bash
    bash -c "cat << EOF > ~/project/deploy/testready/site-config/cas-smp-sssd-volume.yaml
    ---
    # SSSD config map
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: sssd-apply-all
    patch: |-
      - op: add
        path: /spec/controllerTemplate/spec/volumes/-
        value:
          name: sssd-config
          configMap:
            name: sas-sssd-config
            defaultMode: 420
            items:
            - key: SSSD_CONF
              mode: 384
              path: sssd.conf
      - op: add
        path: /spec/controllerTemplate/spec/containers/0/volumeMounts/-
        value:
          name: sssd-config
          mountPath: /etc/sssd
    target:
      group: viya.sas.com
      kind: CASDeployment
      name: .*
      version: v1alpha1
    EOF"
    ```

## adding the token

1. adding the token for external access in a file that can be called by the kustomization.yaml

    ```bash

    # put your registry access into variables
    SAS_CR_USERID=$(cat /opt/raceutils/.token_user)
    SAS_CR_PASSWORD=$(cat /opt/raceutils/.token_pass)

    # create a new secret and put the payload into a variable
    # - this does not really create secret on the server:
    # notice the --dry-run option
    CR_SAS_COM_SECRET="$(kubectl -n viya4 create secret docker-registry cr-access \
        --docker-server=cr.sas.com \
        --docker-username=$SAS_CR_USERID \
        --docker-password=$SAS_CR_PASSWORD \
        --dry-run -o json | jq -r '.data.".dockerconfigjson"')"
    # put the payload decoded into a file

    echo -n $CR_SAS_COM_SECRET | base64 --decode > ~/project/deploy/testready/site-config/cr_sas_com_access.json
    # add this under "secretGenerator" into the kustomization.yaml
    ```

## Kustomization steps

1. and generate the kustomization file

    ```bash
    ## because I have wildcard DNS alias on the first node...
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    bash -c "cat << EOF > ~/project/deploy/testready/kustomization.yaml
    ---
    namespace: testready
    resources:
      - sas-bases/base
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-mpp
      - site-config/gelldap-sssd-configmap.yaml
    transformers:
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/cas-smp-sssd-volume.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=testready.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_URL_SERVICE_TEMPLATE=http://testready.${INGRESS_SUFFIX}
      - name: sas-consul-config
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
    ## patch to lower the CPU across the board!
    patches:
      - path: site-config/cpu_requests_lowerer.yaml
        target:
          kind: Deployment
          labelSelector: sas.com/deployment-base in (spring,go)
    secretGenerator:
      - name: sas-image-pull-secrets
        behavior: replace
        type: kubernetes.io/dockerconfigjson
        files:
          - .dockerconfigjson=site-config/cr_sas_com_access.json

    EOF"

    cd ~/project/deploy/testready
    kustomize build > site.yaml

    git add *
    git commit -m "ready to apply"

    NS=testready

    printf "\n cluster-wide \n\n\n\n\n"
    kubectl apply -n ${NS} -f site.yaml --selector="sas.com/admin=cluster-wide" --prune --prune-whitelist=apps/v1/Deployment --prune-whitelist=core/v1/Service --prune-whitelist=core/v1/ConfigMap --prune-whitelist=extensions/v1beta1/Ingress

    printf "\n cluster-local \n\n\n\n\n"

    kubectl apply  -n ${NS} -f site.yaml --selector="sas.com/admin=cluster-local" --prune --prune-whitelist=apps/v1/Deployment --prune-whitelist=core/v1/Service --prune-whitelist=core/v1/ConfigMap --prune-whitelist=extensions/v1beta1/Ingress

    printf "\n namespace \n\n\n\n\n"

    kubectl apply  -n ${NS} -f site.yaml --selector="sas.com/admin=namespace" --prune --prune-whitelist=apps/v1/Deployment --prune-whitelist=core/v1/Service --prune-whitelist=core/v1/ConfigMap --prune-whitelist=extensions/v1beta1/Ingress

    printf "\n re-apply all \n\n\n\n\n"

    kubectl  -n ${NS} apply -f site.yaml




    ```

    ```bash
    #deploy
    printf "\n* [Viya Drive (testready) URL (HTTP )](http://testready.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Drive (testready) URL (HTTP**S**)](https://testready.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (testready) URL (HTTP)](http://testready.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (testready) URL (HTTP**S**)](https://testready.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md

    echo "watch kubectl get pods,pvc -o wide -n testready"

    #sleep 10

    #time gel_OKViya4 -n testready --wait
    kubectl get pods  -n ${NS}
    kubectl get pvc -n ${NS}

    kubectl -n testready scale deployment --replicas=0 sas-natural-language-understanding

    #gel_OKViya4 -n testready --stop
    #gel_OKViya4 -n testready --start --start-mode random

    ```

<!--
clean up the url file
```bash
sort -u  ~/urls.md  -o ~/urls.md
```
-->
