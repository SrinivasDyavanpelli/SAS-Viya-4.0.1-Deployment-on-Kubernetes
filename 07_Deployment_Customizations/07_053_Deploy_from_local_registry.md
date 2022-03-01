![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

** THIS IS A DRAFT **

# Deploy from local registry

* [Clear things up](#clear-things-up)
* [Prepare deployment](#prepare-deployment)
  * [gelldap and gelmail](#gelldap-and-gelmail)
  * [copy order stuff](#copy-order-stuff)
  * [create mirror file override](#create-mirror-file-override)
  * [create secret to authenticate to local registry](#create-secret-to-authenticate-to-local-registry)
  * [Crunchy postgres needs a special file](#crunchy-postgres-needs-a-special-file)
  * [Creating a TLS-related file in `./site-config/`](#creating-a-tls-related-file-in-site-config)
  * [create kustomization.yaml](#create-kustomizationyaml)
* [Deployed the "mirrored" environment](#deployed-the-mirrored-environment)
* [Generate the URLs for the environment](#generate-the-urls-for-the-environment)
* [Waiting for it](#waiting-for-it)
* [Validate that deployment is working](#validate-that-deployment-is-working)
* [Important: restore access to cr.sas.com](#important-restore-access-to-crsascom)
* [Navigation](#navigation)

## Clear things up

1. remove namespaces if they exist

    ```bash
    kubectl delete ns mirrored
    ```

1. delete other ns

    ```sh
    kubectl delete ns lab dailymirror testready dev gelenv-stable
    ```

1. Remove all cached images from all machines:

    ```bash
    ansible all -m shell -a "docker image prune -a --force | grep reclaimed" -b

    ```

1. Cut off access to the SAS repositories

    ```sh
    ## this will prevent you from accessing the "default" viya images.
    ansible sasnode* -m lineinfile -b \
        -a " dest=/etc/hosts \
            regexp='cr\.sas\.com' \
            line='999.999.999.999 cr.sas.com' \
            state=present \
            backup=yes " \
            --diff

    ```

## Prepare deployment

```bash
kubectl create ns mirrored

```

and

```bash
mkdir -p ~/project/deploy/mirrored
mkdir -p ~/project/deploy/mirrored/site-config

```

### gelldap and gelmail

```bash

cd ~/project/
git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
cd ~/project/gelldap/
git fetch --all
GELLDAP_BRANCH=master
git reset --hard origin/${GELLDAP_BRANCH}

cd ~/project/gelldap/
kustomize build ./no_TLS/ | kubectl -n mirrored apply -f -

cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
       ~/project/deploy/mirrored/site-config/

```

### copy order stuff

```bash
ORDER=9CFHCQ
CADENCE_VERSION=2020.0.6
CADENCE_RELEASE=20201021.1603293493704

ORDER_FILE=$(ls ~/orders/ | grep ${ORDER} | grep ${CADENCE_VERSION} | grep ${CADENCE_RELEASE} )

cp ~/orders/${ORDER_FILE} ~/project/deploy/mirrored/
cd  ~/project/deploy/mirrored/

tar xf *.tgz

```

### create mirror file override

```bash

order=$(echo "$ORDER" | awk '{print tolower($0)}')
echo $order

# harbor.$(hostname -f):443

sed -e "s/{{\ MIRROR\-HOST\ }}/harbor.$(hostname -f):443\/viya/g" \
        ~/project/deploy/mirrored/sas-bases/examples/mirror/mirror.yaml \
        > ~/project/deploy/mirrored/site-config/mirror.yaml

```

### create secret to authenticate to local registry

these images can not be puled from harbor without authentication.

this creates a file you put in site-config that contains the required credentials

```bash
# put your registry access into variables
harbor_user=$(cat ~/exportRobot.json | jq -r .name)
harbor_pass=$(cat ~/exportRobot.json | jq -r .token)

# create a new secret and put the payload into a variable
# - this does not really create secret on the server:
# notice the --dry-run option
CR_SAS_COM_SECRET="$(kubectl -n mirrored create secret docker-registry cr-access \
    --docker-server=harbor.$(hostname -f):443 \
    --docker-username=${harbor_user} \
    --docker-password=${harbor_pass} \
    --dry-run=client -o json | jq -r '.data.".dockerconfigjson"')"

echo $CR_SAS_COM_SECRET | base64 --decode
echo -n $CR_SAS_COM_SECRET | base64 --decode > ~/project/deploy/mirrored/site-config/harbor_access.json

```

### Crunchy postgres needs a special file

1. Following the instructions in the postgres README file, we are told to create this file

    ```bash
    cd ~/project/deploy/mirrored

    mkdir -p ./site-config/postgres

    cat ./sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml | \
        sed 's|\-\ {{\ HBA\-CONF\-HOST\-OR\-HOSTSSL\ }}|- hostssl|g' | \
        sed 's|\ {{\ PASSWORD\-ENCRYPTION\ }}| scram-sha-256|g' \
        > ./site-config/postgres/postgres-custom-config.yaml

    ```

### Creating a TLS-related file in `./site-config/`

By default since the 2020.0.6 version, all internal communications are TLS encrypted.

* Prepare the TLS configuration, according to the doc

    ```bash
    cd ~/project/deploy/mirrored
    mkdir -p ./site-config/security/
    # create the certificate issuer called "sas-viya-issuer"
    sed 's|{{.*}}|sas-viya-issuer|g' ./sas-bases/examples/security/cert-manager-provided-ingress-certificate.yaml  \
        > ./site-config/security/cert-manager-provided-ingress-certificate.yaml
    ```

### create kustomization.yaml

1. now, this:

    ```bash
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    bash -c "cat << EOF > ~/project/deploy/mirrored/kustomization.yaml
    ---
    namespace: mirrored
    resources:
      - sas-bases/base
      - sas-bases/overlays/cert-manager-issuer     # TLS
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/network/ingress/security   # TLS
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      # - sas-bases/overlays/cas-server/auto-resources    # CAS-related
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml  # required for 0.6
    transformers:
      - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
      # - sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      - site-config/mirror.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    configMapGenerator:
      - name: input
        behavior: merge
        literals:
          - IMAGE_REGISTRY=harbor.$(hostname -f):443/viya
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=mirrored.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://mirrored.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
    secretGenerator:
      - name: sas-image-pull-secrets
        behavior: replace
        type: kubernetes.io/dockerconfigjson
        files:
          - .dockerconfigjson=site-config/harbor_access.json
    generators:
      - site-config/postgres/postgres-custom-config.yaml

    EOF"

    ```

## Deployed the "mirrored" environment

1. follow the usual 3-step apply pattern:

    ```bash
    cd  ~/project/deploy/mirrored/

    kustomize build -o site.yaml

    NS=mirrored
    kubectl  -n ${NS}  apply   --selector="sas.com/admin=cluster-wide" -f site.yaml
    kubectl wait  --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd
    kubectl  -n ${NS} apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune
    kubectl  -n ${NS} apply  --selector="sas.com/admin=namespace" -f site.yaml --prune

    # kubectl  -n ${NS} apply -f site.yaml

    ```

## Generate the URLs for the environment

```bash
NS=mirrored
DRIVE_URL="https://$(kubectl -n ${NS} get ing sas-drive-app -o custom-columns='hosts:spec.rules[*].host' --no-headers)/SASDrive/"
echo $DRIVE_URL

printf "\n* [Viya Drive (mirrored) URL (HTTPS)](${DRIVE_URL} )\n\n" | tee -a /home/cloud-user/urls.md
```

## Waiting for it

```bash

gel_OKViya4 -n mirrored --wait -ps
# or
kubectl wait -n mirrored --for=condition=ready pod --selector='app.kubernetes.io/name=sas-readiness'  --timeout=2700s

```

## Validate that deployment is working

log in and use with the environment.

## Important: restore access to cr.sas.com

If you want to be able to do the other exercises, you'll need to restore the access to cr.sas.com that we arbitrarily blocked.

1. do this:

    ```bash

    # re-enable
    ansible sasnode* -m lineinfile -b \
        -a " dest=/etc/hosts \
            regexp='cr\.sas\.com' \
            line='999.999.999.999 cr.sas.com' \
            state=absent \
            backup=yes " \
            --diff

    ```

## Navigation

<!-- startnav -->
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)
* [01 Introduction / 01 032 Assess Readiness of Lab Environment](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md)
* [02 Kubernetes and Containers Fundamentals / 02 131 Learning about Namespaces](/02_Kubernetes_and_Containers_Fundamentals/02_131_Learning_about_Namespaces.md)
* [03 Viya 4 Software Specifics / 03 011 Looking at a Viya 4 environment with Visual Tools DEMO](/03_Viya_4_Software_Specifics/03_011_Looking_at_a_Viya_4_environment_with_Visual_Tools_DEMO.md)
* [03 Viya 4 Software Specifics / 03 031 Create your own Viya order](/03_Viya_4_Software_Specifics/03_031_Create_your_own_Viya_order.md)
* [04 Pre Requisites / 04 061 Pre Requisites automation with ARKCD](/04_Pre-Requisites/04_061_Pre-Requisites_automation_with_ARKCD.md)
* [05 Deployment tools / 05 121 Setup a Windows Client Machine](/05_Deployment_tools/05_121_Setup_a_Windows_Client_Machine.md)
* [06 Deployment Steps / 06 031 Deploying a simple environment](/06_Deployment_Steps/06_031_Deploying_a_simple_environment.md)
* [06 Deployment Steps / 06 051 Deploying Viya with Authentication](/06_Deployment_Steps/06_051_Deploying_Viya_with_Authentication.md)
* [06 Deployment Steps / 06 061 Deploying in a second namespace](/06_Deployment_Steps/06_061_Deploying_in_a_second_namespace.md)
* [06 Deployment Steps / 06 071 Removing Viya deployments](/06_Deployment_Steps/06_071_Removing_Viya_deployments.md)
* [06 Deployment Steps / 06 215 Deploying a programing only environment](/06_Deployment_Steps/06_215_Deploying_a_programing-only_environment.md)
* [07 Deployment Customizations / 07 051 Adding a local registry to k8s](/07_Deployment_Customizations/07_051_Adding_a_local_registry_to_k8s.md)
* [07 Deployment Customizations / 07 052 Using mirrormgr to populate the local registry](/07_Deployment_Customizations/07_052_Using_mirrormgr_to_populate_the_local_registry.md)
* [07 Deployment Customizations / 07 053 Deploy from local registry](/07_Deployment_Customizations/07_053_Deploy_from_local_registry.md)**<-- you are here**
* [11 Azure AKS Deployment / 11 011 Creating an AKS Cluster](/11_Azure_AKS_Deployment/11_011_Creating_an_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 012 Performing Prereqs in AKS](/11_Azure_AKS_Deployment/11_012_Performing_Prereqs_in_AKS.md)
* [11 Azure AKS Deployment / 11 013 Deploying Viya 4 on AKS](/11_Azure_AKS_Deployment/11_013_Deploying_Viya_4_on_AKS.md)
* [11 Azure AKS Deployment / 11 014 Deleting the AKS Cluster](/11_Azure_AKS_Deployment/11_014_Deleting_the_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 015 Fast track with cheatcodes](/11_Azure_AKS_Deployment/11_015_Fast_track_with_cheatcodes.md)
* [11 Azure AKS Deployment / 11 131 CAS Customizations](/11_Azure_AKS_Deployment/11_131_CAS_Customizations.md)
* [11 Azure AKS Deployment / 11 132 Install monitoring and logging](/11_Azure_AKS_Deployment/11_132_Install_monitoring_and_logging.md)
<!-- endnav -->
