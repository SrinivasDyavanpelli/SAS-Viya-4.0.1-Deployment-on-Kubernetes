![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Changing version and adding software

## Replace bundle with new bundle

1. Remove the old Bundles

    ```bash
    rm -rf ~/project/deploy/lab/bundles kustomize.tgz
    ```

1. Download fresher kustomize.tgz

    ```bash
    ## most recent order
    curl -k https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes/raw/orders/orders/kustomize_$(cat ~/order.txt).tgz?inline=false -o ~/project/deploy/lab/kustomize.tgz

    ```

1. Explode the .tgz file

    ```bash
    cd ~/project/deploy/lab/
    tar xvf kustomize.tgz

    ```

1. Now add all the content of the tar to Git

    ```bash
    cd ~/project/deploy/lab/
    git add *
    git commit -m "new .tgz updates bundles"

    ```

## Adjustments needed:

1. re-gen the image list

1. Generate the mirror file:

    ```bash
    ORDER=$(cat ~/order.txt)
    order=$(echo "$ORDER" | awk '{print tolower($0)}')
    echo $order

    sed -e "s/MIRROR_HOST\/.*-testready/gelharbor.race.sas.com\/$order/" ~/project/deploy/lab/bundles/default/examples/mirror/mirror.yaml > ~/project/deploy/lab/site-config/mirror.yaml
    ```

1. update the order # in kustomization.yaml:

    ```bash
    ORDER=$(cat ~/order.txt)
    order=$(echo "$ORDER" | awk '{print tolower($0)}')
    echo $order

    ansible localhost \
     -m replace \
     -a "path=~/project/deploy/lab/kustomization.yaml \
        regexp='9cbq86' \
        replace='$order'" \
        --diff

    ```

1. re-gen site.yaml

    ```bash
    kustomize build > site.yaml
    ```

1. do your git commit:

    ```bash
    cd ~/project/deploy/lab/
    git add *
    git commit -m "update image list in mirror.yaml and kustomization.yaml + regen site"

    ```

1. Try it out in lab, without deleting anything.

    ```bash
    # lots of breaking changes
    # kubectl -n lab delete deployments,pods,services,configmaps,persistentvolumeclaims,ing,replicasets,jobs,statefulsets --all
    kubectl -n lab delete "$(kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed -e 's/,$//')" --all
    kubectl -n lab apply -f site.yaml
    ```

1. because this does not work, we roll things back

    ```bash
    kubectl -n lab delete "$(kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed -e 's/,$//')" --all
    cd ~/project/deploy/lab/
    git checkout caterpillar
    kubectl -n lab apply -f site.yaml
    ```

