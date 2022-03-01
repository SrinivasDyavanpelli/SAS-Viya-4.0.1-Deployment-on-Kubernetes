![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)


## Clean from previous

1. Empty out the namespace

    ```sh
    kubectl -n viya4 delete all,ing,pvc --all

    ```

## Create patch file:

1. lower cpu for everything

    ```bash
    ## david method
    bash -c "cat << EOF > ~/viya4/cpu_requests_lowerer.yaml
    - op: add
      path: /spec/template/spec/containers/0/resources/requests/cpu
      value: "10m"
    EOF"
    ```

1. and update the kustomization file

    ```bash
    ## because I have wildcard DNS alias on the first node...
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    bash -c "cat << EOF > ~/viya4/kustomization.yaml
    namespace: viya4
    resources:
    - bundles/default/bases/sas
    - bundles/default/overlays/network/ingress
    - bundles/default/overlays/internal-postgres
    - bundles/default/overlays/crunchydata
    - bundles/default/overlays/cas-smp
    - sas-sssd-configmap.yaml
    transformers:
    - bundles/default/overlays/required/transformers.yaml
    - bundles/default/overlays/internal-postgres/internal-postgres-transformer.yaml
    #- bundles/default/overlays/cas-smp/cas-smp-transformer-examples.yaml
    ## This tranformer turns RWX storage into RWO storage for CAS, and refdata
    - RWOstorage.yaml
    configMapGenerator:
    - name: ingress-input
      behavior: merge
      literals:
      - INGRESS_HOST=viya4.${INGRESS_SUFFIX}
    - name: sas-shared-config
      behavior: merge
      literals:
      - SAS_URL_SERVICE_TEMPLATE=http://viya4.${INGRESS_SUFFIX}/
    - name: sas-consul-config
      behavior: merge
      files:
        - SITEDEFAULT_CONF=sitedefault.yaml
    secretGenerator:
    - name: sas-image-pull-secrets
      behavior: replace
      type: kubernetes.io/dockerconfigjson
      files:
        - .dockerconfigjson=cr_sas_com_access.json
    ## patch to lower the CPU across the board!
    patches:
    - path: cpu_requests_lowerer.yaml
      target:
        kind: Deployment
        labelSelector: sas.com/deployment-base in (spring,go)
    EOF"

    cd ~/viya4
    kustomize build > site.yaml

    git add *
    git commit -m "Adding patch to lowever CPU Across the board"

    ```

## increase CPU for CAS only

1. increase CPU for CAS

    ```bash
    bash -c "cat << EOF > ~/viya4/cas_resources_values.yaml
    ---
    # Modify memory usage
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-memory-update
    patch: |-
      - op: replace
        path: /spec/controllerTemplate/spec/containers/0/resources/requests/memory
        value:
          1Gi
    target:
      group: viya.sas.com
      kind: CASDeployment
      name: .*
      version: v1alpha1
    ---
    # Modify CPU usage
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-cpu-update
    patch: |-
      - op: replace
        path: /spec/controllerTemplate/spec/containers/0/resources/requests/cpu
        value:
          50m
    target:
      group: viya.sas.com
      kind: CASDeployment
      name: .*
      version: v1alpha1
    ---
    # Modify ephemeral storage
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: cas-ephemeral-storage-update
    patch: |-
      - op: replace
        path: /spec/controllerTemplate/spec/containers/0/resources/requests/ephemeral-storage
        value:
          1Gi
    target:
      group: viya.sas.com
      kind: CASDeployment
      name: .*
      version: v1alpha1
    EOF"
    ```

1. and update the kustomization file

    ```bash
    ## because I have wildcard DNS alias on the first node...
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    bash -c "cat << EOF > ~/viya4/kustomization.yaml
    namespace: viya4
    resources:
    - bundles/default/bases/sas
    - bundles/default/overlays/network/ingress
    - bundles/default/overlays/internal-postgres
    - bundles/default/overlays/crunchydata
    - bundles/default/overlays/cas-smp
    - sas-sssd-configmap.yaml
    transformers:
    - bundles/default/overlays/required/transformers.yaml
    - bundles/default/overlays/internal-postgres/internal-postgres-transformer.yaml
    #- bundles/default/overlays/cas-smp/cas-smp-transformer-examples.yaml
    ## This tranformer turns RWX storage into RWO storage for CAS, and refdata
    - RWOstorage.yaml
    ## This transformer will set the resources for CAS (mem, cpu and disk)
    - cas_resources_values.yaml
    configMapGenerator:
    - name: ingress-input
      behavior: merge
      literals:
      - INGRESS_HOST=viya4.${INGRESS_SUFFIX}
    - name: sas-shared-config
      behavior: merge
      literals:
      - SAS_URL_SERVICE_TEMPLATE=http://viya4.${INGRESS_SUFFIX}/
    - name: sas-consul-config
      behavior: merge
      files:
        - SITEDEFAULT_CONF=sitedefault.yaml
    secretGenerator:
    - name: sas-image-pull-secrets
      behavior: replace
      type: kubernetes.io/dockerconfigjson
      files:
        - .dockerconfigjson=cr_sas_com_access.json
    ## patch to lower the CPU across the board!
    patches:
    - path: cpu_requests_lowerer.yaml
      target:
        kind: Deployment
        labelSelector: sas.com/deployment-base in (spring,go)
    EOF"

    cd ~/viya4
    kustomize build > site.yaml

    git add *
    git commit -m "changing cpu resources"


    kubectl apply -n viya4 -f site.yaml

    # grep -A 1 -ir persistentVolumeClaim\: | grep yaml

    #watch kubectl get pods,pvc -o wide -n viya4
     kubectl get pods,pvc -o wide -n viya4

    exit

    ```


## emptydir patch

1. this

    ```bash
    bash -c "cat << EOF > ~/viya4/emptydir.yaml
    volumes:
      - emptyDir: {}
    EOF"
    ```


## Generate Kustomization.yaml

1. and then

    ```bash
    ## because I have wildcard DNS alias on the first node...
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX


    bash -c "cat << EOF > ~/viya4/kustomization.yaml
    namespace: viya4
    resources:
    - bundles/default/bases/sas
    - bundles/default/overlays/network/ingress
    - bundles/default/overlays/internal-postgres
    - bundles/default/overlays/crunchydata
    - bundles/default/overlays/cas-smp
    transformers:
    - bundles/default/overlays/required/transformers.yaml
    - bundles/default/overlays/internal-postgres/internal-postgres-transformer.yaml
    #- bundles/default/overlays/cas-smp/cas-smp-transformer-examples.yaml
    configMapGenerator:
    - name: ingress-input
      behavior: merge
      literals:
      - INGRESS_HOST=viya4.${INGRESS_SUFFIX}
    - name: sas-shared-config
      behavior: merge
      literals:
      - SAS_URL_SERVICE_TEMPLATE=http://viya4.${INGRESS_SUFFIX}/
    - name: sas-consul-config
      behavior: merge
      files:
        - SITEDEFAULT_CONF=sitedefault.yaml
    secretGenerator:
    - name: sas-image-pull-secrets
      behavior: replace
      type: kubernetes.io/dockerconfigjson
      files:
        - .dockerconfigjson=cr_sas_com_access.json
    patches:
    - path: cpu_requests_lowerer.yaml
      target:
        kind: Deployment
        labelSelector: sas.com/deployment-base in (spring,go)
    #- path: emptydir.yaml
    #  target:
    #    kind: PersistentVolumeClaim
    EOF"

    cd ~/viya4
    kustomize build > site.yaml

    git status

    git add *
    git commit -m "Added the important files"

    ## taint sasnode01
    #kubectl taint nodes sasnode01 key=value:NoSchedule


    kubectl apply -n viya4 -f site.yaml

    # watch kubectl get pods,pvc -o wide -n viya4


    printf "\n* [Viya Drive (viya4) URL (HTTP )](http://viya4.$(hostname -f):80/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md


    printf "\n\n Click on this URL to open VSCode on your server:\n      http://$(hostname -i):8080/ \n"
    docker run -it -p 0.0.0.0:8080:8080 -v "/home/cloud-user/viya4/:/home/coder/viya4/" codercom/code-server

    exit

    ```

## hacking to lower CPU requests

1. cpu requests:

    ```sh

    # https://gitlab.sas.com/cas-dev/containers/blob/master/ktop.sh


    reqs=($(cat base.yml | grep -A 3 Requests | grep cpu | cut -d ':' -f 2))

    reqs=($(cat site.yaml | grep -A 3 requests\: | grep cpu | cut -d ':' -f 2))
    tot=0 ;
    for req in ${reqs[@]}; do this="${req//m}" && tot="$(($tot + $this))"; done ;    echo $tot


    ```

1. reduce the CPU

    ```bash

    cd ~/viya4

    lower_request () {
    ansible localhost -m replace -a \
        "path=~/viya4/site.yaml  \
        regexp='          requests:\n            cpu:\ *$1m' \
        replace='          requests:\n            cpu: $2m' \
        backup=yes " \
        --diff
    }
    lower_request 100 10
    lower_request 250 50

    # nginx.ingress.kubernetes.io/rewrite-target
    # traefik.ingress.kubernetes.io/rewrite-target
    ansible localhost -m replace -a \
        "path=~/viya4/site.yaml  \
        regexp='nginx.ingress.kubernetes.io\/rewrite-target' \
        replace='traefik.ingress.kubernetes.io/rewrite-target' \
        backup=yes " \
        --diff


    git add site.yaml
    git commit -m "lowered the CPU requests"

    cd ~/viya4/
    kubectl apply -n viya4 -f site.yaml


    ```


    ```sh

    #reqs=($(cat lower_site.yaml | grep -A 3 requests\: | grep cpu | cut -d ':' -f 2))
    #tot=0 ;
    #for req in ${reqs[@]}; do this="${req//m}" && tot="$(($tot + $this))"; done ;    echo $tot


    kubectl -n viya4 get pods -o yaml | yq r - 'items[*].spec.containers[*].resources.requests.cpu'
    ```

