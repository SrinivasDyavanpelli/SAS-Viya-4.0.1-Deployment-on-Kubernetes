![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Enabling HA

**DRAFT**

* [Start from gelenv-stable](#start-from-gelenv-stable)
* [Add the ha line in the kustomization.yaml](#add-the-ha-line-in-the-kustomizationyaml)
* [Experimentation](#experimentation)
  * [set the max HPA to 10](#set-the-max-hpa-to-10)

## Start from gelenv-stable

1. execute those steps to quickly generate a "default" deployment d

    ```bash

    cd ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/
    git pull
    git reset --hard origin/stable-2020.0.6
    bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.02.CreateCheatcodes.sh start

    cat ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/01_Introduction/01_000_gelenv_order.sh \
        | grep -v 'apply.*site\.yaml' \
        | sed 's|gelenv\-stable|ha-enabled|g' \
        > ~/project/generate_clone.sh

    #icdiff ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/01_Introduction/01_000_gelenv_order.sh ~/project/generate_clone.sh

    bash -x ~/project/generat de_clone.sh

    cd ~/project/deploy/ha-enabled

    ```

## Add the ha line in the kustomization.yaml

1. add the line

    ```bash
    cp ~/project/deploy/ha-enabled/kustomization.yaml ~/project/deploy/ha-enabled/kustomization.yaml.ha
    printf "
    - command: update
      path: transformers[+]
      value:
        sas-bases/overlays/scaling/ha/enable-ha-transformer.yaml       # enable HA
    " | yq -I 4 w -i -s - ~/project/deploy/ha-enabled/kustomization.yaml.tls.ha

    icdiff ~/project/deploy/ha-enabled/kustomization.yaml ~/project/deploy/ha-enabled/kustomization.yaml.tls.ha

    ```

1. and then, re-symlink and apply

    ```bash
    cd ~/project/deploy/ha-enabled/
    mv  kustomization.yaml.tls kustomization.yaml.tls.noha
    mv   site.yaml site.yaml.tls.noha

    rm kustomization.yaml
    ln -s kustomization.yaml.ha kustomization.yaml
    time kustomize build -o site.yaml.tls.ha
    rm site.yaml
    ln -s site.yaml.tls.ha site.yaml
    ```

1. check how long it takes for the new pods to come fully online

1. confirm that in the meantime, the environment is still accessible

## Experimentation

### set the max HPA to 10

1. fair warning; this is not recommended. it gives a weird result.

    ```bash

    mkdir -p ~/project/deploy/ha-enabled/site-config/ha/

    tee  ~/project/deploy/ha-enabled/site-config/ha/ha10max.yaml > /dev/null << "EOF"
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: enable-ha-hpa-replicas
    patch: |-
      - op: replace
        path: /spec/maxReplicas
        value: 10
      - op: replace
        path: /spec/minReplicas
        value: 2
    target:
      kind: HorizontalPodAutoscaler
      version: v2beta2
      apps: autoscaling
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: enable-ha-centralized-hpa-replicas
    patch: |-
      - op: replace
        path: /spec/maxReplicas
        value: 10
      - op: replace
        path: /spec/minReplicas
        value: 2
    target:
      kind: HorizontalPodAutoscaler
      version: v2beta2
      apps: autoscaling
      annotationSelector: sas.com/ha-class=centralized
    ---
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: enable-ha-centralized-pdb-min-available
    patch: |-
      - op: replace
        path: /spec/minAvailable
        value: 1
    target:
      kind: PodDisruptionBudget
      version: v1beta1
      apps: policy
      annotationSelector: sas.com/ha-class=centralized

    EOF

    ```

1. then update the kustomization.yaml.tls.ha

    ```bash
    ansible localhost \
    -m replace \
    -a  "dest=~/project/deploy/ha-enabled/kustomization.yaml \
        regexp='sas-bases\/overlays\/scaling\/ha\/enable-ha-transformer\.yaml' \
        replace='site-config/ha/ha10max.yaml' \
        backup=yes " \
        --diff
    ```

1. build and apply

    ```bash
    time kustomize build -o site.yaml.tls.ha
    kubectl apply -f site.yaml
    ```
