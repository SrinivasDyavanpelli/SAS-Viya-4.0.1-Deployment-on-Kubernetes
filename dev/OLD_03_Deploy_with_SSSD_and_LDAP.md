
![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Clean from previous

1. Empty out the namespace

    ```sh
    kubectl -n viya4 delete all,ing,pvc --all

    ```

## adding a sitedefault

<!--
1. generate a sitedefault that matches the content of the OpenLDAP:

    ```sh
    tee  ~/viya4/sitedefault.yaml > /dev/null << "EOF"
    ---
    config:
        application:
            sas.identities.providers.ldap.connection:
                host: 'openldap-service.ldap-basic.svc.cluster.local'
                port: '389'
                url: 'ldap://${sas.identities.providers.ldap.connection.host}:${sas.identities.providers.ldap.connection.port}'
                anonymousBind: 'false'
                userDN: 'uid=sasadm,ou=users,dc=gel,dc=com'
                password: 'lnxsas'
                anonymousBind: 'true'
                userDN: 'none'
                password: 'none'
            sas.identities.providers.ldap.group:
                accountId: 'name'
                baseDN: 'ou=groups,dc=gel,dc=com'
                createdDate: 'createTimestamp'
                distinguishedName: 'none'
                member: 'member'
                modifiedDate: 'modifyTimestamp'
                objectClass: 'groupOfNames'
                objectFilter: '(objectClass=groupOfNames)'
                searchFilter: 'dn={0}'
            sas.identities.providers.ldap.user:
                accountId: 'uid'
                baseDN: 'ou=users,dc=gel,dc=com'
                createdDate: 'createTimestamp'
                distinguishedName: 'none'
                memberOf: 'memberOf'
                modifiedDate: 'modifyTimestamp'
                objectClass: 'inetOrgPerson'
                objectFilter: '(objectClass=inetOrgPerson)'
                searchFilter: 'uid={0}'
            sas.identities:
                administrator: 'sasadm'
            sas.logon.initial:
                user: sasboot
                password: lnxsas
    EOF
    ``` -->

1. generate sitedefault for openldap

    ```bash
    tee  ~/viya4/sitedefault.yaml > /dev/null << "EOF"
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
    bash -c "cat << EOF > ~/viya4/sas-sssd-configmap.yaml
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

        ldap_search_base = dc=gel,dc=com

        ldap_user_fullname = displayName

        ldap_group_object_class = groupOfUniqueNames
        ldap_group_name = cn
        ldap_group_gid_number = gidNumber
        ldap_group_member = uniqueMember
    EOF"

    ```

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
    EOF"

    cd ~/viya4
    kustomize build > site.yaml

    git add *
    git commit -m "Modified to add full sitedefault, and SSSD details"



    kubectl apply -n viya4 -f site.yaml

    # grep -A 1 -ir persistentVolumeClaim\: | grep yaml

    #watch kubectl get pods,pvc -o wide -n viya4
     kubectl get pods,pvc -o wide -n viya4

    ```

