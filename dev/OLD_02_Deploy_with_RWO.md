![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploy with RWO storage

## Clean from previous

1. Empty out the namespace

    ```bash
    kubectl -n viya4 delete all,ing,pvc --all

    ```

## as

1. create the patch transformer

    ```bash

    bash -c "cat << EOF > ~/viya4/RWOstorage.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: pvc-access-mode-casdata
    patch: |-
     - op: replace
       path: /spec/accessModes
       value:
         - ReadWriteOnce
    target:
      kind: PersistentVolumeClaim
      name: cas-default-data
      version: v1
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: pvc-access-mode-cas-permstore
    patch: |-
     - op: replace
       path: /spec/accessModes
       value:
         - ReadWriteOnce
    target:
      kind: PersistentVolumeClaim
      name: cas-default-permstore
      version: v1
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: pvc-access-mode-sas-refdata
    patch: |-
     - op: replace
       path: /spec/accessModes
       value:
         - ReadWriteOnce
    target:
      kind: PersistentVolumeClaim
      name: sas-refdata-pvc
      version: v1
    EOF"

    ```

1. and then ...

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
    EOF"

    cd ~/viya4
    kustomize build > site.yaml

    git add *
    git commit -m "Modified it to have RWO instead of RWX"


    kubectl apply -n viya4 -f site.yaml

    # grep -A 1 -ir persistentVolumeClaim\: | grep yaml

    time  gel_OKViya4 -n viya4 --wait

    ```

