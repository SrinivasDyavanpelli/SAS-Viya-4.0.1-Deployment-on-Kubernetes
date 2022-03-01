![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploying in a second namespace

## Copy the files



## Query

### Based on site.yaml content

1. Let's create a function for this

    ```bash
    gel_add_cpu_site () {
        reqs=($(cat site.yaml | grep -A 3 requests\: | grep cpu | cut -d ':' -f 2))
        tot=0 ;
        for req in ${reqs[@]}; do this="${req//m}" && tot="$(($tot + $this))"; done ;
    printf "based on site.yaml, the total CPU requests is: $tot (milicores)\n\n"
    }
    ```

1. And let's run it against our Lab namespace:

    ```bash
    cd ~/project/deploy/lab
    gel_add_cpu_site

    ```

    <details> <summary>Click here to see the expected output</summary>

    ```log
    based on site.yaml, the total CPU requests is: 23030 (milicores)
    ```

    </details>

### Based on Kubernetes info

1. Create a function to do this:

    ```bash
    gel_add_cpu_k8s () {
        stuff=($(kubectl -n $1 get pods -o custom-columns='Name:metadata.name, Resources:spec.containers[*].resources'))
        myreqs=()
        for thing in ${stuff[@]}; do if [[ $thing == *requests* ]]; then myreqs+=( $thing ); fi; done
        total=0
        for req in ${myreqs[@]}; do numreq=$(echo "$req" | sed 's/[^0-9]*//g') && total="$(($total + $numreq))"; done
        printf "based on the content of the '$1' namespace, the total CPU requests is: $total (milicores)\n\n"
    }
    gel_add_cpu_k8s lab

    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    based on the content of the 'lab' namespace, the total CPU requests is: 250 (milicores)
    ```

    </details>

<!--
### Based on site.yaml content, using yq

1. Let's install yq

    ```bash

    sudo -u cloud-user bash -c "ansible localhost \
            -b --become-user=root \
            -m get_url -a  \
                \"url=https://github.com/mikefarah/yq/releases/download/3.2.1/yq_linux_amd64 \
                dest=/usr/local/bin/yq \
                validate_certs=no \
                force=yes \
                owner=root \
                mode=0755 \
                backup=yes\" \
                --diff"

    ```

1. And let's run it against our Lab namespace:

    ```sh
    cat site.yaml | yq r -d'*' - spec[0].template[0].spec[0].containers[0].resources[0]
    ```
-->

## Lower

### Create branch

1. Let's create the Caterpillar branch

    ```bash
    cd ~/project/deploy/lab/
    git checkout master
    git branch caterpillar
    git checkout caterpillar
    ```

### Create patch file to lower CPU requests down to 10m

1. lower cpu for everything

    ```bash
    bash -c "cat << EOF > ~/project/deploy/lab/site-config/cpu_requests_lowerer.yaml
    ---
    - op: add
      path: /spec/template/spec/containers/0/resources/requests/cpu
      value: "10m"
    EOF"
    ```

### Create the Kustomization file for caterpillar in lab

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

    commonAnnotations:
      sas.com/viyanimal: "caterpillar"
    EOF"
    ```

1. review the differences we've introduced:

    ```bash
    git --no-pager diff kustomization.yaml

    ```

## Re-gen manifest

1. do this:

    ```bash
    kustomize build -o site.yaml
    ```

1. commit to version control

    ```bash
    cd ~/project/deploy/lab
    git  --no-pager  diff site.yaml
    git add *
    git commit -m "lowered the CPUs"
    ```

## Apply it

1. apply in Lab

    ```bash
    cd ~/project/deploy/lab
    kubectl apply -n lab -f site.yaml
    ```

1. test that it worked:

    ```bash
    cd ~/project/deploy/lab
    gel_add_cpu_site
    ```

1. since it worked, we merge caterpillar into master

    ```bash
    cd ~/project/deploy/lab
    git  checkout master
    git merge caterpillar

    ```

## Query again

1. do this:

    ```bash
    cd ~/project/deploy/lab
    gel_add_cpu_site
    ```

## Implement also in Dev, using the power of git

1. We need to do a pull with rebase. (don't ask)

    ```bash
    ## I need to review this and make sure it truly works.
    cd ~/project/deploy/dev
    git pull --rebase
    kubectl apply -n dev -f site.yaml
    ```

## reset default namespace

1. Make default the default again:

    ```bash
    kubectl config set-context --current --namespace=default
    ```
