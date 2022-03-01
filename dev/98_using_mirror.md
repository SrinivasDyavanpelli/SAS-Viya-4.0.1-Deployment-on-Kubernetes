![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)


# Deploy Environment with mirror

* [Cleaning for a failed attempt](#cleaning-for-a-failed-attempt)
* [Set the namespace once and for all](#set-the-namespace-once-and-for-all)
* [prep the files](#prep-the-files)
* [adding images](#adding-images)
* [adding a sssd.conf](#adding-a-sssdconf)


<!--
    ```bash

    undo_it () {

    if kubectl get ns | grep -q 'dolphin\ '
    then
        kubectl -n dolphin delete deployments --all
        kubectl -n dolphin delete services --all
        kubectl -n dolphin delete pods --all
        kubectl -n dolphin delete ing --all
        kubectl -n dolphin delete all --all
        kubectl delete ns dolphin
        rm -rf ~/project/ldap/basic

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

    ```sh

    if kubectl get ns | grep -q 'dolphin\ '
    then
        kubectl -n dolphin delete all,ing --all
        kubectl delete ns dolphin
    fi
    kubectl create ns dolphin
    ```

<!--
1. Nuke the namespace from orbit

    ```sh
    ## sometimes deleting the ns gets stuck. In case it happens:
    NS=dolphin
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

## Set the namespace once and for all

1. let's choose to work in the dolphin namespace by default

    ```bash
    kubectl config set-context --current --namespace dolphin
    ```

## prep the files

1. create a working dir

    ```bash
    rm -rf ~/project/deploy/dolphin/
    mkdir -p ~/project/deploy/dolphin/site-config/
    ```

1. Get the .tgz  (this will have to change ...)

    ```bash
    ## most recent order
    #curl -k https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes/raw/orders/orders/kustomize_$(cat ~/order.txt).tgz?inline=false -o ~/project/deploy/dolphin/kustomize.tgz
    curl -k https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes/raw/orders/orders/kustomize_$(cat ~/stable_order.txt).tgz?inline=false -o ~/project/deploy/dolphin/kustomize.tgz

    ```

1. do the first commit (.tgz)

    ```bash
    cd ~/project/deploy/dolphin/
    git add kustomize.tgz
    git commit -m " adding the .tgz file, just because"

    ```

1. explode the .tar file

    ```bash
    cd ~/project/deploy/dolphin/
    tar xvf kustomize.tgz

    ```

1. Now add all the content of the tar to Git

    ```bash
    cd ~/project/deploy/dolphin/
    git add *
    git commit -m "exploded .tgz. this is the result"

    ```

1. Create a namespace for Viya 4

    ```bash
    kubectl create ns dolphin
    kubectl get ns

    ```


## adding images

1. generate sitedefault for openldap

    ```bash
    tee  ~/project/deploy/dolphin/site-config/sitedefault.yaml > /dev/null << "EOF"
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
    bash -c "cat << EOF > ~/project/deploy/dolphin/site-config/sas-sssd-configmap.yaml
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



1. and update the kustomization file

    ```bash
    ## because I have wildcard DNS alias on the first node...
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX
    ORDER=$(cat ~/stable_order.txt)
    order=$(echo "$ORDER" | awk '{print tolower($0)}')
    echo $order


    bash -c "cat << EOF > ~/project/deploy/dolphin/kustomization.yaml
    namespace: dolphin
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
    - site-config/mirror.yaml
    configMapGenerator:
    - name: ingress-input
      behavior: merge
      literals:
      - INGRESS_HOST=dolphin.${INGRESS_SUFFIX}
    - name: sas-shared-config
      behavior: merge
      literals:
      - SAS_URL_SERVICE_TEMPLATE=http://dolphin.${INGRESS_SUFFIX}/
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
    EOF"

    bash -c "cat << EOF > ~/project/deploy/dolphin/gen_and_apply.sh

    #!/bin/bash

    ORDER=$(cat ~/stable_order.txt)
    order=$(echo "$ORDER" | awk '{print tolower($0)}')
    echo $order

    sed -e "s/MIRROR_HOST\/.*-docker/gelharbor.race.sas.com\/$order/" bundles/default/examples/mirror/mirror.yaml > site-config/mirror.yaml

    ## to be tested
    chmod 666 ./bundles/default/overlays/crunchydata/kustomization.yaml
    sed -i.bak "s/cr\.sas\.com\/.*-docker-testready/gelharbor.race.sas.com\/$order/"  ./bundles/default/overlays/crunchydata/kustomization.yaml

    kustomize build > site.yaml

    echo kubectl apply -n dolphin -f ./site.yaml
    echo watch kubectl get pods -n dolphin
    EOF"



    cd ~/project/deploy/dolphin
    kustomize build > site.yaml

    git add *
    git commit -m "dopphin is ready , after image updates"


    kubectl apply -f site.yaml

    ```

    ```bash
    #deploy
    printf "\n* [Viya Drive (dolphin) URL (HTTP)](http://dolphin.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Drive (dolphin) URL (HTTP**S**)](https://dolphin.$(hostname -f)/SASDrive )\n\n" | tee -a /home/cloud-user/urls.md

    echo "watch kubectl get pods,pvc -o wide -n dolphin"

    sleep 10

    gel_OKViya4 -n dolphin --wait

    ```
