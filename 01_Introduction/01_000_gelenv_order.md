![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploy the "gelenv-stable" GEL order (all products)

This is not for human consumption. This is an automated way of deploying a template environment.

Just execute:

```sh

#testing
cd ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/
git pull
git reset --hard origin/master
bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.02.CreateCheatcodes.sh start
bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/01_Introduction/01_000_gelenv_order.sh

```

Stop reading now

<!--
```sh

# testing
cd ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/
git pull
git reset --hard origin/stable-2020.0.6
bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.02.CreateCheatcodes.sh start

 bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/07_Deployment_Customizations/07_031_Adding_a_local_registry_to_k8s.sh
 bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/07_Deployment_Customizations/07_032_Using_mirrormgr_to_populate_the_local_registry.sh
 bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/07_Deployment_Customizations/07_033_Deploy_from_local_registry.sh

bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/06_Deployment_Steps/06_011_*.sh
bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/06_Deployment_Steps/06_012_*.sh
bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/06_Deployment_Steps/06_013_*.sh
bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/06_Deployment_Steps/06_014_*.sh

bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/01_Introduction/01_000_gelenv_order.sh

```
 -->

* [steps](#steps)
  * [default values for variables:](#default-values-for-variables)
  * [wipe namespace](#wipe-namespace)
  * [Labels and taints](#labels-and-taints)
  * [prep](#prep)
  * [ldap](#ldap)
  * [get order](#get-order)
  * [mirror (not used)](#mirror-not-used)
  * [label for compute](#label-for-compute)
  * [Daily update-checker run](#daily-update-checker-run)
  * [MPP CAS:](#mpp-cas)
  * [Crunchy postgres needs a special file](#crunchy-postgres-needs-a-special-file)
  * [TLS work](#tls-work)
  * [Kustomization](#kustomization)
  * [Urls](#urls)
  * [Generate "variations" from `gelenv-stable`](#generate-variations-from-gelenv-stable)
    * [Do one with HA-enabled](#do-one-with-ha-enabled)
    * [Do one for single-machine](#do-one-for-single-machine)
  * [wait for it](#wait-for-it)
  * [testing various reboots](#testing-various-reboots)

## steps

### default values for variables:

```bash
NS=${NS:-gelenv-stable}
CADENCE_NAME=${CADENCE_NAME:-stable}
CADENCE_VERSION=${CADENCE_VERSION:-2020.0.6}
ORDER=${ORDER:-9CDZDD}
INGRESS_PREFIX=${INGRESS_PREFIX:-${NS}}
FOLDER_NAME=${FOLDER_NAME:-~/project/deploy/${NS}}
```

### wipe namespace

```sh
#wipe clean
kubectl delete ns ${NS}

rm -rf ${FOLDER_NAME}

```

### Labels and taints

* clear it all up

    ```bash
    kubectl label nodes \
        intnode01 intnode02 intnode03 intnode04 intnode05 intnode06 intnode07 intnode08 intnode09 intnode10 intnode11  \
        workload.sas.com/class-          --overwrite
    kubectl taint nodes \
        intnode01 intnode02 intnode03 intnode04 intnode05 intnode06 intnode07 intnode08 intnode09 intnode10 intnode11  \
        workload.sas.com/class-          --overwrite
    ```

* start with labels

    ```bash
    kubectl label nodes \
        intnode01   \
        workload.sas.com/class=connect          --overwrite
    kubectl label nodes \
         intnode02   \
        workload.sas.com/class=compute          --overwrite
    kubectl label nodes \
         intnode03    \
        workload.sas.com/class=stateful          --overwrite
    kubectl label nodes \
         intnode04    \
        workload.sas.com/class=stateless          --overwrite
    kubectl label nodes \
        intnode05 intnode06 intnode07 intnode08 intnode09 intnode10 intnode11   \
        workload.sas.com/class=cas          --overwrite

    ```

* no taints yet

### prep

1. create folders and namespaces

    ```bash
    mkdir -p ~/project
    mkdir -p ${FOLDER_NAME}
    mkdir -p ${FOLDER_NAME}/site-config

    tee  ${FOLDER_NAME}/namespace.yaml > /dev/null << EOF
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: ${NS}
      labels:
        name: "${NS}_namespace"
    EOF

    kubectl apply -f ${FOLDER_NAME}/namespace.yaml

    kubectl get ns

    ```

### ldap

1. gelldap and gelmail

    ```bash

    cd ~/project/
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/project/gelldap/
    git fetch --all
    GELLDAP_BRANCH=master
    git reset --hard origin/${GELLDAP_BRANCH}

    cd ~/project/gelldap/
    kustomize build ./no_TLS/ | kubectl -n ${NS} apply -f -

    cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
           ${FOLDER_NAME}/site-config/

    ```

### get order

1. copy order stuff

    ```bash

    # update orders:
    bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.23.copy.orders.sh start

    # tmp override:
    #CADENCE_NAME=fast
    #CADENCE_VERSION=2020

    ORDER_FILE=$(ls ~/orders/ \
        | grep ${ORDER} \
        | grep ${CADENCE_NAME} \
        | grep ${CADENCE_VERSION} \
        | sort \
        | tail -n 1 \
        )

    #SASViyaV4_9CDZDD_0_stable_2020.0.4_20200821.1598037827526_deploymentAssets_2020-08-24T165225
    echo $ORDER_FILE

    cp ~/orders/${ORDER_FILE} ${FOLDER_NAME}/
    cd  ${FOLDER_NAME}/

    rm -rf ./sas-bases/
    tar xf ${ORDER_FILE}

    ```

<!--
1. override with mirrored order:

    ```sh
    rm -rf ./sas-bases/
    rm -rf *.tgz

    echo "09RG3K" > ~/dailymirror.txt

    curl https://gelweb.race.sas.com/scripts/PSGEL255/orders/$(cat ~/dailymirror.txt).kustomize.tgz \
        -o ${FOLDER_NAME}/dailymirror.tgz

    cd  ${FOLDER_NAME}/

    tar xf dailymirror.tgz

    ```
 -->

### mirror (not used)

1. create mirror file override

    ```bash

    #order=$(echo "$(cat ~/dailymirror.txt)" | awk '{print tolower($0)}')
    #echo $order

    sed -e "s/{{\ MIRROR\-HOST\ }}/gelharbor.race.sas.com\/$order/" \
            ${FOLDER_NAME}/sas-bases/examples/mirror/mirror.yaml \
            > ${FOLDER_NAME}/site-config/mirror.yaml

    ```

### label for compute

1. label one machine

    ```bash
    kubectl label nodes \
        intnode05  \
       workload.sas.com/class=compute --overwrite

    ```

### Daily update-checker run

1. create a transformer to run this very often:

    ```bash

    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/daily_update_check.yaml
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: daily-update-check
    patch: |-
      - op: replace
        path: /spec/schedule
        value: '00,15,30,45 * * * *'
      - op: replace
        path: /spec/successfulJobsHistoryLimit
        value: 24
    target:
      name: sas-update-checker
      kind: CronJob
    EOF"

    ```

### MPP CAS:

1. MPP CAS with secondary controller

    ```bash
    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/cas-default_secondary_controller.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-backup-default
    patch: |-
       - op: replace
         path: /spec/backupControllers
         value:
           1
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    bash -c "cat << EOF > ${FOLDER_NAME}/site-config/cas-default_workers.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-workers-default
    patch: |-
       - op: replace
         path: /spec/workers
         value:
           4
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    ```

### Crunchy postgres needs a special file

1. so the postgres readme states:

    ```bash

    mkdir -p ${FOLDER_NAME}/site-config/postgres
    #cp ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml \
    #    ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    cat ${FOLDER_NAME}/sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml | \
        sed 's|\-\ {{\ HBA\-CONF\-HOST\-OR\-HOSTSSL\ }}|- hostssl|g' | \
        sed 's|\ {{\ PASSWORD\-ENCRYPTION\ }}| scram-sha-256|g' \
        > ${FOLDER_NAME}/site-config/postgres/postgres-custom-config.yaml

    ```

### TLS work

* from Stuart

    ```bash
    mkdir -p ${FOLDER_NAME}/site-config/security/cacerts
    mkdir -p ${FOLDER_NAME}/site-config/security/cert-manager-issuer

    # Download Intermediate CA cert and key
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/intermediate.key.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem

    # Download CA cert
    curl -sk https://gelgitlab.race.sas.com/GEL/workshops/PSGEL263-sas-viya-4.0.1-advanced-topics-in-authentication/-/raw/master/scripts/TLS/GELEnvRootCA/ca_cert.pem \
    -o ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem


    # Create Ingress YAML
    tee ${FOLDER_NAME}/site-config/security/cert-manager-provided-ingress-certificate.yaml > /dev/null <<EOF
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: sas-cert-manager-ingress-annotation-transformer
    patch: |-
      - op: add
        path: /metadata/annotations/cert-manager.io~1issuer
        value: sas-viya-issuer
    target:
      kind: Ingress
      name: .*
    EOF

    # Create Issuer YAML files
    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/kustomization.yaml > /dev/null <<EOF
    resources:
    - resources.yaml
    EOF

    export BASE64_CA=`cat ${FOLDER_NAME}/site-config/security/cacerts/ca_cert.pem|base64|tr -d '\n'`
    export BASE64_CERT=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.cert.pem|base64|tr -d '\n'`
    export BASE64_KEY=`cat ${FOLDER_NAME}/site-config/security/cacerts/intermediate.key.pem|base64|tr -d '\n'`

    tee ${FOLDER_NAME}/site-config/security/cert-manager-issuer/resources.yaml > /dev/null <<EOF
    ---
    # sas-viya-ca-certificate.yaml
    # ............................
    apiVersion: v1
    kind: Secret
    metadata:
      name: sas-viya-ca-certificate-secret
    data:
      ca.crt: $BASE64_CA
      tls.crt: $BASE64_CERT
      tls.key: $BASE64_KEY
    ---
    # sas-viya-issuer.yaml
    # ....................
    apiVersion: cert-manager.io/v1alpha2
    kind: Issuer
    metadata:
      name: sas-viya-issuer
    spec:
      ca:
        secretName: sas-viya-ca-certificate-secret
    EOF



    ```

### Kustomization

1. create kustomization.yaml

    ```bash

    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    cd ${FOLDER_NAME}
    #rm ./gelldap
    #ln -s ~/project/gelldap ./gelldap

    bash -c "cat << EOF > ${FOLDER_NAME}/kustomization.yaml.tls
    ---
    namespace: ${NS}
    resources:
      - sas-bases/base
      #- sas-bases/overlays/cert-manager-issuer     # TLS
      - site-config/security/cert-manager-issuer
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/network/ingress/security   # TLS
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      #- gelldap/no_TLS
      #- sas-bases/overlays/cas-server/auto-resources    # CAS-related
    ## added in .0.6
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml
    transformers:
      - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
      - site-config/daily_update_check.yaml      # change the frequency of the update-check
      #- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - site-config/cas-default_secondary_controller.yaml
      - site-config/cas-default_workers.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    generators:
      - site-config/postgres/postgres-custom-config.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
    EOF"


    bash -c "cat << EOF > ${FOLDER_NAME}/kustomization.yaml.notls
    ---
    namespace: ${NS}
    resources:
      - sas-bases/base
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      #- gelldap/no_TLS
      #- sas-bases/overlays/cas-server/auto-resources    # CAS-related
    ## added in .0.6
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml
    transformers:
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/daily_update_check.yaml      # change the frequency of the update-check
      #- sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - site-config/cas-default_secondary_controller.yaml
      - site-config/cas-default_workers.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=http://${INGRESS_PREFIX}.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
    EOF"

    cd  ${FOLDER_NAME}/

    rm -f kustomization.yaml
    ln -s kustomization.yaml.notls kustomization.yaml
    time kustomize build -o site.yaml.notls

    rm -f kustomization.yaml
    ln -s kustomization.yaml.tls kustomization.yaml
    time kustomize build -o site.yaml.tls

    ## choose which one we want
    rm -f site.yaml
    ln -s site.yaml.tls site.yaml

    kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml                    | tee /tmp/site_apply1.log
    time kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd   | tee /tmp/site_wait.log
    kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune             | tee /tmp/site_apply2.log
    kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune                 | tee /tmp/site_apply3.log

    # kubectl  -n ${NS} apply -f site.yaml

    ```

1. if you want to watch it

    ```sh
    watch ' kubectl -n gelenv-stable get po -o wide | grep -v "1/1" '
    ```

### Urls

1. Urls

    ```bash
    #printf "\n* [Viya Drive (${NS}) URL (HTTP )](http://${INGRESS_PREFIX}.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Drive (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    #printf "\n* [Viya Environment Manager (${NS}) URL (HTTP)](http://${INGRESS_PREFIX}.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (${NS}) URL (HTTP**S**)](https://${INGRESS_PREFIX}.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    ```

### Generate "variations" from `gelenv-stable`

#### Do one with HA-enabled

* HA stuff

    ```bash
    ## all you need to do to apply the variation is:
    source <( cat /opt/raceutils/.bootstrap.txt  )
    source <( cat /opt/raceutils/.id.txt  )

    if  [ "$collection_size" -gt "7"  ] ; then
    ## all you need to do to apply the variation is:
    mkdir -p ~/project/deploy/gelenv-stable_HA/

    ## copy the HA transformer
    cp ~/project/deploy/gelenv-stable/sas-bases/overlays/scaling/ha/enable-ha-transformer.yaml \
        ~/project/deploy/gelenv-stable_HA/

    bash -c "cat << EOF > ~/project/deploy/gelenv-stable_HA/kustomization.yaml
    ---
    resources:
      - ../gelenv-stable/        ## get same content as gelenv-stable
    transformers:
      - enable-ha-transformer.yaml
    EOF"

    cd ~/project/deploy/gelenv-stable_HA/
    time kustomize build -o site.yaml


        cd ~/project/deploy/gelenv-stable_HA/

        #kubectl apply -f  ~/project/deploy/gelenv-stable_HA/site.yaml
        kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml                    | tee /tmp/site_apply1.log
        time kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd   | tee /tmp/site_wait.log
        kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune             | tee /tmp/site_apply2.log
        kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune                 | tee /tmp/site_apply3.log
    fi

    ```

#### Do one for single-machine

* single machine stuff

    ```bash
    ## all you need to do to apply the variation is:
    source <( cat /opt/raceutils/.bootstrap.txt  )
    source <( cat /opt/raceutils/.id.txt  )

    if  [ "$collection_size" = "2"  ] ; then


    mkdir -p ~/project/deploy/gelenv-stable_single/
    mkdir -p ~/project/deploy/gelenv-stable_single/site-config

    stop_these="(sas-business-rules-services,sas-connect,sas-connect-spawner,sas-data-quality-services,sas-decision-manager-app,sas-decisions-definitions,sas-esp-operator,sas-forecasting-comparison,sas-forecasting-events,sas-forecasting-exploration,sas-forecasting-filters,sas-forecasting-pipelines,sas-forecasting-services,sas-job-flow-scheduling,sas-microanalytic-score,sas-model-management,sas-model-manager-app,sas-subject-contacts,as-text-analyticssas-text-cas-data-management,sas-text-categorization,sas-text-concepts,sas-text-parsing,sas-text-sentiment,sas-text-topics,sas-topic-management,sas-workflow,sas-workflow-definition-history,sas-workflow-manager-app)"

    bash -c "cat << EOF > ${FOLDER_NAME}_single/site-config/cas-default_secondary_controller.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-backup-default
    patch: |-
       - op: replace
         path: /spec/backupControllers
         value:
           0
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"

    bash -c "cat << EOF > ${FOLDER_NAME}_single/site-config/cas-default_workers.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-add-workers-default
    patch: |-
       - op: replace
         path: /spec/workers
         value:
           0
    target:
      group: viya.sas.com
      kind: CASDeployment
      labelSelector: "sas.com/cas-server-default"
      version: v1alpha1
    EOF"


    bash -c "cat << EOF > ~/project/deploy/gelenv-stable_single/minimal_deploy.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: partial_stop
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 0
    target:
      kind: Deployment
      version: v1
      group: apps
      labelSelector: app.kubernetes.io/name in ${stop_these}
    ---

    EOF"

    bash -c "cat << EOF > ~/project/deploy/gelenv-stable_single/cpu_requests_lowerer.yaml
    - op: add
      path: /spec/template/spec/containers/0/resources/requests/cpu
      value: "10m"
    EOF"


    bash -c "cat << EOF > ~/project/deploy/gelenv-stable_single/kustomization.yaml
    ---
    resources:
      - ../gelenv-stable/        ## get same content as gelenv-stable
    transformers:
      - minimal_deploy.yaml
      - site-config/cas-default_secondary_controller.yaml
      - site-config/cas-default_workers.yaml

    ## patch to lower the CPU across the board
    patches:
      - path: cpu_requests_lowerer.yaml
        target:
          kind: Deployment
          LabelSelector: sas.com/deployment-base in (spring,golang)
      - path: cpu_requests_lowerer.yaml
        target:
          kind: StatefulSet
    EOF"


    cd ~/project/deploy/gelenv-stable_single/
    time kustomize build -o site.yaml





        kubectl -n cert-manager scale deployment cert-manager --replicas=1
        kubectl -n nginx scale deployment my-nginx-nginx-ingress-controller --replicas=1

        kubectl label nodes \
            $(hostname)  \
            workload.sas.com/class=compute --overwrite

        cd ~/project/deploy/gelenv-stable_single/
        kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml                    | tee /tmp/site_apply1.log
        time kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd   | tee /tmp/site_wait.log
        kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune             | tee /tmp/site_apply2.log
        kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune                 | tee /tmp/site_apply3.log

        kubectl  -n ${NS} delete pods --all
        #gel_OKViya4 -n ${NS} --stop
        #gel_OKViya4 -n ${NS} --start

        #kubectl -n gelenv-stable scale deployment --all --replicas=0
        #kubectl -n gelenv-stable scale sts --all --replicas=0
        #kubectl -n gelenv-stable scale sts sas-consul-server   --replicas=3
        #kubectl -n gelenv-stable scale sts sas-rabbitmq-server   --replicas=3
        #kubectl -n gelenv-stable scale sts sas-cacheserver   --replicas=3

    fi

    ```

### wait for it

1. Waiting on it

    ```sh

    time gel_OKViya4 -n ${NS} --wait -ps --min-success-rate 50
    # and then:
    time kubectl wait -n ${NS} --for=condition=ready pod --selector='app.kubernetes.io/name=sas-readiness'  --timeout=2700s

    ```

### testing various reboots

1. this is to be run manually (very time consuming)

    ```sh

    tee  /tmp/multi-restarts.sh > /dev/null << "EOF"

    # reset

    function reset (){
        kubectl delete ns lab testready dev dailymirror

        items_to_delete=$(kubectl api-resources --namespaced=true --verbs=delete -o name \
            | grep -v event \
            | tr "\n" "," \
            | sed -e 's/,$//')

        #kubectl -n ${NS} delete $items_to_delete -l sas.com/deployment=sas-viya
        #kubectl -n ${NS} delete $items_to_delete -l vendor=crunchydata

        gel_OKViya4 -n ${NS} --stop
        ansible sasnode* -m shell -a "docker image prune -a --force"
    }

    reset

    time gel_OKViya4 -n ${NS} --start --wait -ps --start-mode parallel \
        --manifest ${FOLDER_NAME}/site.yaml \
        | tee /tmp/parallel_start.$(date +%F_%T).log

    reset

    time gel_OKViya4 -n ${NS} --start --wait -ps --start-mode sequential \
        --manifest ${FOLDER_NAME}/site.yaml \
        | tee /tmp/sequential_start.$(date +%F_%T).log

    EOF

    SessName=restart
    tmux new -s $SessName -d
    tmux send-keys -t $SessName " bash -x /tmp/multi-restarts.sh "  C-m
    #    tmux a -t $SessName

    ```
