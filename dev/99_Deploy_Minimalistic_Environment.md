![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)


# Deploy Minimal Environment

* [Cleaning for a failed attempt](#cleaning-for-a-failed-attempt)
* [create a namespace, and make it the default one](#create-a-namespace-and-make-it-the-default-one)
* [prep the files](#prep-the-files)
* [Storage transformer](#storage-transformer)
* [adding a sssd.conf](#adding-a-sssdconf)
* [Create patch file to lower CPU requests down to 10m](#create-patch-file-to-lower-cpu-requests-down-to-10m)
* [Create a patch file to disable Natural Language understanding](#create-a-patch-file-to-disable-natural-language-understanding)
* [Mirroring steps](#mirroring-steps)
* [Kustomization steps](#kustomization-steps)

<!--
    ```bash

    undo_it () {

    if kubectl get ns | grep -q 'functional\ '
    then
        kubectl -n functional delete deployments --all
        kubectl -n functional delete services --all
        kubectl -n functional delete pods --all --force --grace-period=0
        kubectl -n functional delete ing --all
        kubectl -n functional delete all --all
        kubectl delete ns functional

    fi

    }

    #undo_it

    if  [ "$1" == "reset" ]; then
        exit
    fi

    ```
 -->

## Cleaning for a failed attempt

1. Empty out the namespace

    ```bash

    if kubectl get ns | grep -q 'functional\ '
    then
        kubectl -n functional delete all,ing --all
        kubectl delete ns functional
    fi

    ```

<!--
1. Nuke the namespace from orbit

    ```sh
    ## sometimes deleting the ns gets stuck. In case it happens:
    NS=functional
    if kubectl get ns | grep -q "$NS\ " ; then
        echo "found $NS namespace. deleting it";
        kubectl get namespace $NS -o json | grep -v kubernetes > tmp.json
        kubectl delete ns $NS --force --grace-period=0

        nohup kubectl proxy  &
        sleep 5
        curl -k -H "Content-Type: application/json" -X PUT --data-binary @tmp.json http://localhost:8001/api/v1/namespaces/$NS/finalize
        kubectl get ns
    else
        echo "$NS namespace does not exist. ";
    fi
    ```
-->

## create a namespace, and make it the default one

1. Create a namespace for Viya 4

    ```bash
    kubectl create ns functional
    kubectl get ns

    ```

1. let's choose to work in the dolphin namespace by default

    ```bash
    kubectl config set-context --current --namespace functional

    ```

## prep the files

1. create a working dir

    ```bash
    rm -rf ~/project/deploy/functional/
    mkdir -p ~/project/deploy/functional/site-config/
    ```

1. Get the .tgz  (this will have to change ...)

    ```bash
    ## most recent order
    curl -k https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes/raw/orders/orders/kustomize_$(cat ~/stable_order.txt).tgz?inline=false -o ~/project/deploy/functional/kustomize.tgz

    ```

1. do the first commit (.tgz)

    ```bash
    cd ~/project/deploy/functional/

    my_name=erwan-granger

    git init
    git config --local user.email "$my_name@ItDoesNotMatter.com"
    git config --local user.name "$my_name"


    git add kustomize.tgz
    git commit -m " adding the .tgz file, just because"

    ```

1. explode the .tar file

    ```bash
    cd ~/project/deploy/functional/
    tar xvf kustomize.tgz

    ```

1. Now add all the content of the tar to Git

    ```bash
    cd ~/project/deploy/functional/
    git add *
    git commit -m "exploded .tgz. this is the result"

    ```

## Storage transformer

1. create the patch transformer for storage

    ```bash

    bash -c "cat << EOF > ~/project/deploy/functional/site-config/RWOstorage.yaml
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

1. generate sitedefault for openldap

    ```bash
    tee  ~/project/deploy/functional/site-config/sitedefault.yaml > /dev/null << "EOF"
    config:
        application:
            sas.identities.providers.ldap.connection:
                host: openldap-service.ldap-basic.svc.cluster.local
                password: lnxsas
                port: 389
                userDN: cn=admin,dc=gel,dc=com
                url: ldap://${sas.identities.providers.ldap.connection.host}:${sas.identities.providers.ldap.connection.port}
            sas.identities.providers.ldap.group:
                accountId: 'cn'
                baseDN: 'dc=gel,dc=com'
                objectFilter: '(objectClass=groupOfUniqueNames)'
            sas.identities.providers.ldap.user:
                accountId: 'cn'
                baseDN: 'dc=gel,dc=com'
                objectFilter: '(objectClass=person)'
            sas.identities:
                administrator: 'sasadm'
            sas.logon.initial:
                user: sasboot
                password: lnxsas
    EOF
    ```

## adding a sssd.conf

1. and the sssd

    ```bash
    bash -c "cat << EOF > ~/project/deploy/functional/site-config/sas-sssd-configmap.yaml
    ---
    # Source: default/templates/sas-sssd-configmap.yaml
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: sas-sssd-config
    data:
      SSSD_CONF: |
        [sssd]
        config_file_version = 2
        domains = gel.com
        services = nss, pam

        [nss]

        [pam]

        [domain/gel.com]

        # uncomment for high level of debugging
        #debug_level = 9

        id_provider = ldap
        auth_provider = ldap
        chpass_provider = ldap
        access_provider = permit

        ldap_uri = ldap://openldap-service.ldap-basic.svc.cluster.local:389

        ldap_default_bind_dn = cn=admin,dc=gel,dc=com
        ldap_default_authtok = lnxsas

        ldap_tls_reqcert = never
        ldap_id_use_start_tls = false

        ldap_search_base = dc=gel,dc=com

        ldap_user_fullname = displayName

        ldap_group_object_class = groupOfUniqueNames
        ldap_group_name = cn
        ldap_group_gid_number = gidNumber
        ldap_group_member = uniqueMember
    EOF"

    ```

## Create patch file to lower CPU requests down to 10m

1. lower cpu for everything

    ```bash
    ## david method
    bash -c "cat << EOF > ~/project/deploy/functional/site-config/cpu_requests_lowerer.yaml
    - op: add
      path: /spec/template/spec/containers/0/resources/requests/cpu
      value: "10m"
    EOF"
    ```

## Create a patch file to disable Natural Language understanding

* The "Natural Language understanding" pod consumes a large amount of memory in the cluster.
We want a customization of the deployment, so when we deploy Viya  the replicaset for the naturallanguageunderstanding deployment is set to 0.

    ```bash
    bash -c "cat << EOF > ~/project/deploy/functional/site-config/replica_0_naturallanguage.yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: naturallanguageunderstanding
    spec:
      replicas: 0
    EOF"
    ```

## Mirroring steps

1. Generate the mirror file:

    ```bash
    ORDER=$(cat ~/stable_order.txt)
    order=$(echo "$ORDER" | awk '{print tolower($0)}')
    echo $order

    sed -e "s/MIRROR_HOST\/.*-docker/gelharbor.race.sas.com\/$order/" bundles/default/examples/mirror/mirror.yaml > ~/project/deploy/functional/site-config/mirror.yaml
    ```

1. Hack away at bundles, to correct some hard-coded things.

    ```bash
    chmod 666 ./bundles/default/overlays/crunchydata/kustomization.yaml
    sed -i.bak "s/cr\.sas\.com\/.*-docker-testready/gelharbor.race.sas.com\/$order/"  ./bundles/default/overlays/crunchydata/kustomization.yaml
    ```

## Kustomization steps

1. and generate the kustomization file

    ```bash
    ## because I have wildcard DNS alias on the first node...
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    bash -c "cat << EOF > ~/project/deploy/functional/kustomization.yaml
    namespace: functional
    resources:
    - bundles/default/bases/sas
    - bundles/default/overlays/network/ingress
    - bundles/default/overlays/internal-postgres
    - bundles/default/overlays/crunchydata
    - bundles/default/overlays/cas-smp
    - site-config/sas-sssd-configmap.yaml
    transformers:
    - bundles/default/overlays/required/transformers.yaml
    - bundles/default/overlays/internal-postgres/internal-postgres-transformer.yaml
    ## This tranformer turns RWX storage into RWO storage for CAS, and refdata
    - site-config/RWOstorage.yaml
    - site-config/mirror.yaml
    configMapGenerator:
    - name: ingress-input
      behavior: merge
      literals:
      - INGRESS_HOST=functional.${INGRESS_SUFFIX}
    - name: sas-shared-config
      behavior: merge
      literals:
      - SAS_URL_SERVICE_TEMPLATE=http://functional.${INGRESS_SUFFIX}/
    - name: sas-consul-config
      behavior: merge
      files:
        - SITEDEFAULT_CONF=site-config/sitedefault.yaml
    - name: input
      behavior: merge
      literals:
        - IMAGE_REGISTRY=gelharbor.race.sas.com
    - name: ccp-image-location
      behavior: merge
      literals:
        - CCP_IMAGE_PATH=gelharbor.race.sas.com/$order/crunchydata-postgres
    ## patch to lower the CPU across the board!
    patches:
    - path: site-config/cpu_requests_lowerer.yaml
      target:
        kind: Deployment
        labelSelector: sas.com/deployment-base in (spring,go)
    ## patch to set replica 0 for naturallanguageunderstanding as it uses too much RAM
    patchesStrategicMerge:
    - site-config/replica_0_naturallanguage.yaml
    EOF"

    cd ~/project/deploy/functional
    kustomize build > site.yaml

    git add *
    git commit -m "ready to apply"

    kubectl -n functional apply -f site.yaml

    ```

    ```bash
    #deploy
    printf "\n* [Viya Drive (functional) URL (HTTP )](http://functional.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Drive (functional) URL (HTTP**S**)](https://functional.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (functional) URL (HTTP)](http://functional.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (functional) URL (HTTP**S**)](https://functional.$(hostname -f)/SASEnvironmentManager )\n\n" | tee -a /home/cloud-user/urls.md


    echo "watch kubectl get pods,pvc -o wide -n functional"

    sleep 10


    time gel_OKViya4 -n functional --wait

    ```
