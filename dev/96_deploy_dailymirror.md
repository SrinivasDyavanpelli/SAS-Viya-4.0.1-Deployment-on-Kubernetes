![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploying from Test-Ready (mirrored)

* [Storing the Order number](#storing-the-order-number)
* [Cleaning for a failed attempt](#cleaning-for-a-failed-attempt)
* [prep the files](#prep-the-files)
* [create a namespace, and make it the default one](#create-a-namespace-and-make-it-the-default-one)
* [taint the nodes](#taint-the-nodes)
* [Deploy the GELLDAP utility into the dailymirror namespace](#deploy-the-gelldap-utility-into-the-dailymirror-namespace)
* [Create patch file to lower CPU requests down to 10m](#create-patch-file-to-lower-cpu-requests-down-to-10m)
  * [Adding a mirror reference file](#adding-a-mirror-reference-file)
* [Kustomization steps](#kustomization-steps)
* [wait for the deployment to come up](#wait-for-the-deployment-to-come-up)

<!--
    ```sh

    undo_it () {

    if kubectl get ns | grep -q 'dailymirror\ '
    then
        kubectl -n dailymirror delete deployments --all --force --grace-period=0
        kubectl -n dailymirror delete services --all --force --grace-period=0
        kubectl -n dailymirror delete pods --all --force --grace-period=0
        kubectl -n dailymirror delete ing --all --force --grace-period=0
        kubectl -n dailymirror delete all --all --force --grace-period=0
        kubectl -n dailymirror delete pvc --all --force --grace-period=0
        #kubectl delete ns dailymirror

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
        #hollow_out_ns dailymirror
        if kubectl get ns | grep -q 'dailymirror\ '
        then
            #kubectl -n dailymirror delete all,ing,events,pvc --all
            time kubectl delete ns dailymirror
        fi
    fi

    if  [ "$1" == "reset" ]; then
        exit
    fi

    ```
 -->

## Storing the Order number

```bash
echo "09RG3K" > ~/dailymirror.txt
```

## Cleaning for a failed attempt

1. Empty out the namespace

    ```bash

    if kubectl get ns | grep -q 'dailymirror\ '
    then
        kubectl delete ns dailymirror
        #kubectl -n dailymirror delete all,ing,events,pvc --all
        #kubectl delete ns dailymirror
        kubectl create ns dailymirror
    fi

    ```

## prep the files

1. create a working dir

    ```bash
    #rm -rf ~/project/deploy/dailymirror/
    rm -rf ~/project/deploy/dailymirror/*
    rm -rf ~/project/deploy/dailymirror/.git
    mkdir -p ~/project/deploy/dailymirror/site-config/
    ```

1. Get the .tgz  (this will have to change ...)

    ```bash
    ## most recent order
    curl https://gelweb.race.sas.com/scripts/PSGEL255/orders/$(cat ~/dailymirror.txt).kustomize.tgz \
        -o ~/project/deploy/dailymirror/kustomize.tgz

    cd ~/project/deploy/dailymirror/
    tar xf kustomize.tgz

    ls -altr

    ```

1. do the first commit (.tgz)

    ```bash
    cd ~/project/deploy/dailymirror/

    my_name=erwan-granger

    git init
    git config --local user.email "$my_name@ItDoesNotMatter.com"
    git config --local user.name "$my_name"


    git add kustomize.tgz
    git commit -m " adding the .tgz file, just because"

    ```

1. Now add all the content of the tar to Git

    ```bash
    cd ~/project/deploy/dailymirror/
    git add *
    git commit -m "exploded .tgz. this is the result"

    ```

## create a namespace, and make it the default one

1. Create a namespace for Viya 4

    ```bash
    tee  ~/project/deploy/dailymirror/namespace.yaml > /dev/null << "EOF"
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: dailymirror
      labels:
        name: "dailymirror"
    EOF

    kubectl apply -f ~/project/deploy/dailymirror/namespace.yaml
    kubectl get ns

    ```

1. let's choose to work in the dailymirror namespace by default

    ```bash
    kubectl config set-context --current --namespace dailymirror

    ```

## taint the nodes

```bash
kubectl label nodes \
        intnode05  \
       workload.sas.com/class=compute --overwrite
```

## Deploy the GELLDAP utility into the dailymirror namespace

1. This step has been highly automated to make your life easier. You're welcome

1. Clone the GELLDAP project into the project directory

    ```bash
    cd ~/project/
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/project/gelldap/
    git fetch --all
    GELLDAP_BRANCH=master
    git reset --hard origin/${GELLDAP_BRANCH}

    ```

1. Deploy GELLDAP into the namespace

    ```bash
    cd ~/project/gelldap/
    kustomize build ./no_TLS/ | kubectl -n dailymirror apply -f -

    ```

1. copy the provided file in the proper location:

    ```bash
    cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
       ~/project/deploy/dailymirror/site-config/

    ```

## Create patch file to lower CPU requests down to 10m

1. lower cpu for everything

    ```bash
    bash -c "cat << EOF > ~/project/deploy/dailymirror/site-config/cpu_requests_lowerer.yaml
    - op: add
      path: /spec/template/spec/containers/0/resources/requests/cpu
      value: "10m"
    EOF"

    ```

### Adding a mirror reference file

Because we are working in RACE, we cannot access the SAS Network.

So instead of using the default images that come with our order, we are going to be using a cached (mirrored) version of these images.

These instructions will hopefully change because right now, it's complicated and confusing.

1. Generate the mirror file:

    ```bash
    ORDER=$(cat ~/dailymirror.txt)
    order=$(echo "$ORDER" | awk '{print tolower($0)}')
    echo $order

    sed -e "s/{{\ MIRROR\-HOST\ }}/gelharbor.race.sas.com\/$order/" \
         ~/project/deploy/dailymirror/sas-bases/examples/mirror/mirror.yaml \
         > ~/project/deploy/dailymirror/site-config/mirror.yaml
    ```

## Kustomization steps

1. and generate the kustomization file

    ```bash
    ORDER=$(cat ~/dailymirror.txt)
    order=$(echo "$ORDER" | awk '{print tolower($0)}')
    echo $order

    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    bash -c "cat << EOF > ~/project/deploy/dailymirror/kustomization.yaml
    ---
    namespace: dailymirror
    resources:
      - sas-bases/base
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-mpp
    transformers:
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/mirror.yaml
    configMapGenerator:
      - name: input
        behavior: merge
        literals:
          - IMAGE_REGISTRY=gelharbor.race.sas.com/${order}
      - name: ccp-image-location
        behavior: merge
        literals:
          - CCP_IMAGE_REPO=gelharbor.race.sas.com/${order}
          - CCP_IMAGE_PATH=gelharbor.race.sas.com/${order}
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=dailymirror.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_URL_SERVICE_TEMPLATE=http://dailymirror.${INGRESS_SUFFIX}
      - name: sas-consul-config
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
    ## patch to lower the CPU across the board!
    patches:
      - path: site-config/cpu_requests_lowerer.yaml
        target:
          kind: Deployment
          LabelSelector: sas.com/deployment-base in (spring,go)
    commonAnnotations:
      sas.com/viyanimal: "dailymirror"
    EOF"
    ```

1. at this point, we can create site1.yaml

    ```bash

    cd ~/project/deploy/dailymirror
    yamllint kustomization.yaml
    kustomize build -o site.yaml

    git add *
    git commit -m "ready to apply"

    ```

1. apply in one shot

    ```bash
    printf "\n re-apply all \n\n\n\n\n"

    kubectl -n dailymirror apply -f site.yaml

    ```

1. alternatively, one by one:

    ```sh

    printf "\n cluster-wide \n\n\n\n\n"
    kubectl apply -n dailymirror -f site.yaml --selector="sas.com/admin=cluster-wide" --prune --prune-whitelist=apps/v1/Deployment --prune-whitelist=core/v1/Service --prune-whitelist=core/v1/ConfigMap --prune-whitelist=extensions/v1beta1/Ingress

    printf "\n cluster-local \n\n\n\n\n"

    kubectl apply -n dailymirror -f site.yaml --selector="sas.com/admin=cluster-local" --prune --prune-whitelist=apps/v1/Deployment --prune-whitelist=core/v1/Service --prune-whitelist=core/v1/ConfigMap --prune-whitelist=extensions/v1beta1/Ingress

    printf "\n namespace \n\n\n\n\n"

    kubectl apply -n dailymirror -f site.yaml --selector="sas.com/admin=namespace" --prune --prune-whitelist=apps/v1/Deployment --prune-whitelist=core/v1/Service --prune-whitelist=core/v1/ConfigMap --prune-whitelist=extensions/v1beta1/Ingress

    ```

    ```bash
    #deploy
    printf "\n* [Viya Drive (dailymirror) URL (HTTP )](http://dailymirror.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Drive (dailymirror) URL (HTTP**S**)](https://dailymirror.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (dailymirror) URL (HTTP)](http://dailymirror.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (dailymirror) URL (HTTP**S**)](https://dailymirror.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md


    echo "watch kubectl get pods,pvc -o wide -n dailymirror"

    #sleep 10

    #time gel_OKViya4 -n dailymirror --wait
    kubectl get pods -n dailymirror
    kubectl get pvc -n dailymirror

    #gel_OKViya4 -n dailymirror --stop
    #gel_OKViya4 -n dailymirror --start --start-mode random

    ```

## wait for the deployment to come up

1. create the list of ingresses to check:

    ```bash

    cd ~/project/deploy/dailymirror/

    kubectl -n dailymirror get ing \
        -o custom-columns='host:spec.rules[*].host, backendpath:spec.rules[*].http.paths[*].path' \
        --no-headers | \
        sed 's/[(/|$)(*)]//g' | \
         awk  '{  print "http://" $1 "/" $2 "/" }' \
          | sed 's/\.\//\//g' \
          | sed 's/\.\,\//\//g' \
          | sort -u  \
          | grep -Ev 'jobDefinitions|config-reconciler' \
          > ./inglist.txt
    ```

1. verify the list:

    ```bash
    cat  ~/project/deploy/dailymirror/inglist.txt
    ```

1. read the doc:

    ```sh
    VIYACURLCHECK=https://raw.githubusercontent.com/erwangranger/ViyaCurlCheck/master/viyacurlcheck.sh
    curl ${VIYACURLCHECK} | bash -h

    ```

1. check the URLs

    ```sh
    curl ${VIYACURLCHECK} | bash -s -- -u "$(cat ~/project/deploy/dailymirror/inglist.txt)" \
        --min-success-rate 95 \
        --max-retries 30 \
        --retry-gap 60

    pwd
    ```

