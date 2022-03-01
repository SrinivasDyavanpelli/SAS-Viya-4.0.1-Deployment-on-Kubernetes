![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Using kustomize to configure LDAP

1. start from the existing files in `~/project/ldap-basic/`

1. Create a kustomization.yaml


    ```bash
    tee ~/project/ldap/basic/kustomization.yaml > /dev/null <<'EOF'
    ---
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
      - 01-ldap-basic-namespace.yaml
      - 02-openldap-configmap.yaml
      - 03-openldap-deployment.yaml
      - 04-openldap-service.yaml
      - 05-php-ldap-admin-deployment.yaml
      - 06-php-ldap-admin-service.yaml
      - 07-php-ldap-admin-ingress.yaml
    EOF

    cd ~/project/ldap/basic/

    kustomize build -o ldap-basic.yaml

    pygmentize ldap-basic.yaml

    yamllint ldap-basic.yaml

    yamllint *.yaml
    ```
