![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploying with alternate number of replicas

## Codename Dragonfly

The dragonfly deployment will

* have zero replicas for **Naturallanguage**
* have 3 replicas for
  * saslogon

## Work in 'lab' and create new branch (dragonfly)

1. Go to the lab folder and create the "dragonfly" branch from "caterpillar"

    ```bash
    cd ~/project/deploy/lab
    git checkout caterpillar
    #git branch -D dragonfly
    git branch dragonfly
    git checkout dragonfly
    ```

## Work

### Extra files

1. The "Natural Language understanding" pod consumes a large amount of memory in the cluster.
We want a customization of the deployment, so when we deploy Viya  the replicaset for the naturallanguageunderstanding deployment is set to 0.

    ```bash
    bash -c "cat << EOF > ~/project/deploy/lab/site-config/replica_0_naturallanguage.yaml
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: naturallanguageunderstanding
    spec:
      replicas: 0
    EOF"
    ```

1. create the helper file specifying 3 replicas

    ```bash
    bash -c "cat << EOF > ~/project/deploy/lab/site-config/3replicas.yaml
    ---
    # apiVersion: apps/v1
    # kind: Deployment
    # metadata:
    #   name: wildcard
    # spec:
    #   replicas: 3
    - op: add
      path: /spec/replicas
      value: 3

    EOF"
    ```

## Update Kustomization.yaml

1. The updated **kustomization.yaml** file for dev has too look like:

    ```bash
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    order=$(cat ~/stable_order.txt | awk '{print tolower($0)}')

    bash -c "cat << EOF > ~/project/deploy/lab/kustomization.yaml
    ---
    namespace: lab
    resources:
      - bundles/default/bases/sas
      - bundles/default/overlays/network/ingress
      - bundles/default/overlays/internal-postgres
      - bundles/default/overlays/crunchydata
      - bundles/default/overlays/cas-smp
      ##  this enables SSSD in the compsrv pod(s)
      - site-config/gelldap-sssd-configmap.yaml
    transformers:
      - bundles/default/overlays/required/transformers.yaml
      - bundles/default/overlays/internal-postgres/internal-postgres-transformer.yaml
      ## This overrides the image names to use our privately stored images
      - site-config/mirror.yaml
      ##  this enables SSSD in the CAS pod(s)
      - site-config/cas-smp-sssd-volume.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=tryit.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_URL_SERVICE_TEMPLATE=http://tryit.${INGRESS_SUFFIX}/
      ## This injects content into consul. You can add, but not replace
      - name: sas-consul-config
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
      # Two more overrides are needed for the Images:
      - name: input
        behavior: merge
        literals:
          - IMAGE_REGISTRY=gelharbor.race.sas.com
      - name: ccp-image-location
        behavior: merge
        literals:
          - CCP_IMAGE_PATH=gelharbor.race.sas.com/$order/crunchydata-postgres
    patches:
      ## this enable SSSD in the compsrv pod
      - path: site-config/compsrv-sssd-volume.yaml
        target:
          kind: Deployment
          labelSelector: app.kubernetes.io/name in (compsrv)

      ## patch to lower the CPU across the board!
      - path: site-config/cpu_requests_lowerer.yaml
        target:
          kind: Deployment
          labelSelector: sas.com/deployment-base in (spring,go)
      ## lower the cpu for rabbit
      - path: site-config/cpu_requests_lowerer.yaml
        target:
          kind: Deployment
          name: rabbitmq
      - path: site-config/3replicas.yaml
        target:
          kind: Deployment
          #labelselector: app.kubernetes.io/name notin (authorization,cacheserver,cachelocator,configuration,consul,identities,htmlcommons,postgres,rabbitmq,saslogon,types)
          labelselector: app.kubernetes.io/name in (saslogon)
    patchesStrategicMerge:
      ## patch to set replica 0 for naturallanguageunderstanding as it uses too much RAM
      - site-config/replica_0_naturallanguage.yaml
    commonAnnotations:
      sas.com/viyanimal: "dragonfly"
    EOF"
    ```

1. review the differences we've introduced:

    ```bash
    git --no-pager diff kustomization.yaml

    ```



1. update kustomization.yaml

    ```bash
    bash -c "cat << EOF >> ~/project/deploy/lab/kustomization.yaml
    EOF"

1. re-gen the site.yaml

    ```bash
    kustomize build > site.yaml

    ```

1. commit to version control

    ```bash
    cd ~/project/deploy/lab
    git add *
    git commit -m "set replicas to zero for naturalllanguageunderstanding"
    ```


## Zero replicas

1. create the helper file specifying 3 replicas

    ```bash
    bash -c "cat << EOF > ~/project/deploy/lab/site-config/scaletozero.yaml
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: scale-deployments-to-zero
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 0
    target:
      group: apps
      kind: Deployment
      version: v1
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: scale-stateful-set-to-zero
    patch: |-
      - op: replace
        path: /spec/replicas
        value: 0
    target:
      group: apps
      kind: StatefulSet
      version: v1
    ---
    EOF"
    ```

## Kustomizations

    ```bash
    ## because I have wildcard DNS alias on the first node...
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    order=$(cat ~/stable_order.txt | awk '{print tolower($0)}')

    bash -c "cat << EOF > ~/project/deploy/lab/kustomization.yaml
    ---
    namespace: lab
    resources:
      - bundles/default/bases/sas
      - bundles/default/overlays/network/ingress
      - bundles/default/overlays/internal-postgres
      - bundles/default/overlays/crunchydata
      - bundles/default/overlays/cas-smp
      ##  this enables SSSD in the compsrv pod(s)
      - site-config/sas-sssd-configmap.yaml
    transformers:
      - bundles/default/overlays/required/transformers.yaml
      - bundles/default/overlays/internal-postgres/internal-postgres-transformer.yaml
      ## This overrides the image names to use our privately stored images
      - site-config/mirror.yaml
      ##  this enables SSSD in the CAS pod(s)
      - site-config/cas-smp-sssd-volume.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=tryit.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_URL_SERVICE_TEMPLATE=http://tryit.${INGRESS_SUFFIX}/
      ## This injects content into consul. You can add, but not replace
      - name: sas-consul-config
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/sitedefault.yaml
      # Two more overrides are needed for the Images:
      - name: input
        behavior: merge
        literals:
          - IMAGE_REGISTRY=gelharbor.race.sas.com
      - name: ccp-image-location
        behavior: merge
        literals:
          - CCP_IMAGE_PATH=gelharbor.race.sas.com/$order/crunchydata-postgres
    patches:
      ## this enable SSSD in the compsrv pod
      - path: site-config/compsrv-sssd-volume.yaml
        target:
          kind: Deployment
          labelSelector: app.kubernetes.io/name in (compsrv)
    EOF"




1. add this transformer

    ```sh
      - site-config/scaletozero.yaml
    ```

