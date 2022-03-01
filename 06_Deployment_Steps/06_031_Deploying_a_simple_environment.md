![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploying a simple environment

* [Overview of steps](#overview-of-steps)
* [Cleaning for a failed attempt (Optional)](#cleaning-for-a-failed-attempt-optional)
* [Prep Steps](#prep-steps)
  * [Label and taint your nodes](#label-and-taint-your-nodes)
  * [Prepare standard folder structure](#prepare-standard-folder-structure)
  * [Obtain and extract the .tgz file](#obtain-and-extract-the-tgz-file)
  * [Creating a namespace](#creating-a-namespace)
  * [Creating a sitedefault file](#creating-a-sitedefault-file)
  * [Crunchy postgres needs a special file](#crunchy-postgres-needs-a-special-file)
  * [Creating a TLS-related file in `./site-config/`](#creating-a-tls-related-file-in-site-config)
  * [Create your Kustomization.yaml file](#create-your-kustomizationyaml-file)
* [Build step](#build-step)
  * [Generate the manifest file](#generate-the-manifest-file)
* [Deploy step](#deploy-step)
  * [Apply the manifest file](#apply-the-manifest-file)
* [Store the URLs for later](#store-the-urls-for-later)
* [watching the environment come up in tmux](#watching-the-environment-come-up-in-tmux)
* [Validation](#validation)
* [Reset the default namespace](#reset-the-default-namespace)
* [Navigation](#navigation)

## Overview of steps

1. We will create a namespace called "lab"
1. We will use an ingress that has a prefix of "tryit.".
1. We will deploy viya env into Lab
1. We will configure full-stack TLS as this is now the default deployment

## Cleaning for a failed attempt (Optional)

If you need to re-run through this exercise and want to make sure that old content is not causing issues, you'd have to clean things up.

The following steps will only work if you go over all this a second time. Skip them the first time around.

1. Empty out the namespace

    ```sh
    ## writing it out the long way:

    kubectl -n lab delete deployments --all

    kubectl -n lab delete pods --all

    kubectl -n lab delete services --all

    kubectl -n lab delete persistentvolumeclaims  --all

    ```

1. But deleting the namespace will really make sure we have a clean slate, so just do it ;->

    ```bash
    ## or the short way
    kubectl delete ns lab

    ```

## Prep Steps

### Label and taint your nodes

Labelling and tainting your nodes allow you to:
* direct Viya pods to go on specific nodes
* make other pods stay away from these nodes

This topic is covered in more details in other places. For the time being, follow the instructions given to you here.  Of course, if you are curious Google can help explain that taints are a way of tagging nodes for specific workloads. Other parts of this workshop will dwelve more deeply into those topics.

The commands below will ensure that:
* Previous taints/labels are fully removed if any were present.
* Compute pods will start on INTNODE05
* CAS Pods will start on INTNODE04

1. Review the Taints:

    ```bash
    kubectl get nodes -o=custom-columns=NODENAME:.metadata.name,TAINTS:.spec.taints
    ```

1. Review the Labels:

    ```bash
    kubectl get nodes -o=custom-columns=NODENAME:.metadata.name,LABELS:.metadata.labels
    ```

1. Remove taints and labels from nodes:

    ```bash
    kubectl label nodes intnode01 intnode02 intnode03 intnode04 intnode05 workload.sas.com/class-          --overwrite
    kubectl taint nodes intnode01 intnode02 intnode03 intnode04 intnode05 workload.sas.com/class-          --overwrite

    ```

1. If you don't have any taints or labels, the above commands will return some errors. That is expected.

1. Assign the new labels

    ```bash
    # do all of the labels
    kubectl label nodes intnode01           workload.sas.com/class=stateful           --overwrite
    kubectl label nodes intnode02 intnode03 workload.sas.com/class=stateless          --overwrite
    kubectl label nodes intnode04           workload.sas.com/class=cas                --overwrite
    kubectl label nodes intnode05           workload.sas.com/class=compute            --overwrite

    # only do one of the taints
    #kubectl taint nodes intnode01                                               workload.sas.com/class=stateful:NoSchedule --overwrite
    #kubectl taint nodes intnode02 intnode03                                     workload.sas.com/class=stateless:NoSchedule --overwrite
    kubectl taint nodes intnode04                                               workload.sas.com/class=cas:NoSchedule --overwrite
    #kubectl taint nodes intnode05                                               workload.sas.com/class=compute:NoSchedule --overwrite

    ```


### Prepare standard folder structure

1. Create a working dir for the lab environment

    ```bash
    rm -rf ~/project/deploy/lab/.git
    rm -rf ~/project/deploy/lab/*
    mkdir -p ~/project/deploy/lab
    mkdir -p ~/project/deploy/lab/site-config/

    ```

### Obtain and extract the .tgz file

1. For this series of exercises, we will use a specific, pre-created order.

1. The .tgz file that we need to use is the `~/orders` folder

1. We will store that name in a text file so we can re-use it later:

    ```bash
    CADENCE_NAME=${CADENCE_NAME:-stable}
    CADENCE_VERSION=${CADENCE_VERSION:-2020.0.6}
    ORDER=${ORDER:-9CFHCQ}

    ORDER_FILE=$(ls ~/orders/ \
        | grep ${ORDER} \
        | grep ${CADENCE_NAME} \
        | grep ${CADENCE_VERSION} \
        | sort \
        | tail -n 1 \
        )
    echo ${ORDER_FILE} | tee ~/simple_order.txt
    ```

1. If you list the contents of the folder `~/orders/`, you will see that it's one among other many other orders used in this workshop.

    ```bash
    ls ~/orders/

    ```

1. Let's copy this order into our "lab" working area:

    ```bash
    cp ~/orders/$(cat ~/simple_order.txt) ~/project/deploy/lab/
    cd ~/project/deploy/lab/
    ls -al
    ```

1. Explode the .tgz file

    ```bash
    cd ~/project/deploy/lab/
    tar xf $(cat ~/simple_order.txt)

    ```

1. Confirm that it created the `sas-bases` folder and content by typing ` ls -al ` :

    <details><summary>Click here to see the expected output</summary>

    ```log
    total 292
    drwxrwxr-x 4 cloud-user cloud-user    144 Jul 24 10:20 .
    drwxrwxr-x 4 cloud-user cloud-user     28 Jul 24 09:09 ..
    drwxrwxr-x 5 cloud-user cloud-user     88 Jul 24 10:20 sas-bases
    drwxrwxr-x 2 cloud-user cloud-user      6 Jul 24 10:19 site-config
    -rw-r--r-- 1 cloud-user cloud-user 298599 Jul 24 10:19 SASViyaV4_9CFHCQ_stable_2020.0.6_20201021.1603293493704_deploymentAssets_2020-09-25T165510.tgz
    ```

    </details>

### Creating a namespace

1. (re)Create lab namespace for our lab environment

    ```bash
    kubectl create ns lab
    kubectl get ns

    ```

1. Make it the default namespace:

    ```bash
    kubectl config set-context --current --namespace=lab

    ```

### Creating a sitedefault file

1. Generate a `sitedefault.yaml` just to define the default password for the sasboot account

    ```bash
    tee  ~/project/deploy/lab/site-config/sitedefault.yaml > /dev/null << "EOF"
    ---
    config:
      application:
        sas.logon.initial:
          user: sasboot
          password: lnxsas
    EOF
    ```

1. I know this is not technically required, but it will make your life so much easier, it's worth the extra file.

1. If you don't do this, you'll have to reset the sasboot password by following [these instructions](http://pubshelpcenter.unx.sas.com:8080/test/?docsetId=dplyml0phy0dkr&docsetTarget=n0jnud7mxkxkstn18ub6ylsdyl95.htm&docsetVersion=v_006&locale=en)

### Crunchy postgres needs a special file

1. Following the instructions in the postgres README file, we are told to create this file

    ```bash
    cd ~/project/deploy/lab

    mkdir -p ./site-config/postgres

    cat ./sas-bases/examples/configure-postgres/internal/custom-config/postgres-custom-config.yaml | \
        sed 's|\-\ {{\ HBA\-CONF\-HOST\-OR\-HOSTSSL\ }}|- hostssl|g' | \
        sed 's|\ {{\ PASSWORD\-ENCRYPTION\ }}| scram-sha-256|g' \
        > ./site-config/postgres/postgres-custom-config.yaml

    ```

### Creating a TLS-related file in `./site-config/`

By default since the 2020.0.6 version, all internal communications are TLS encrypted.

* Prepare the TLS configuration

    ```bash
    cd ~/project/deploy/lab
    mkdir -p ./site-config/security/
    # create the certificate issuer called "sas-viya-issuer"
    sed 's|{{.*}}|sas-viya-issuer|g' ./sas-bases/examples/security/cert-manager-provided-ingress-certificate.yaml  \
        > ./site-config/security/cert-manager-provided-ingress-certificate.yaml
    ```

### Create your Kustomization.yaml file

1. The kustomization.yaml file should have the following content.

    ```bash
    INGRESS_SUFFIX=$(hostname -f)
    echo $INGRESS_SUFFIX

    bash -c "cat << EOF > ~/project/deploy/lab/kustomization.yaml
    ---
    namespace: lab
    resources:
      - sas-bases/base
      - sas-bases/overlays/cert-manager-issuer     # TLS
      - sas-bases/overlays/network/ingress
      - sas-bases/overlays/network/ingress/security   # TLS
      - sas-bases/overlays/internal-postgres
      - sas-bases/overlays/crunchydata
      - sas-bases/overlays/cas-server
      - sas-bases/overlays/update-checker       # added update checker
      - sas-bases/overlays/cas-server/auto-resources    # CAS-related
    configurations:
      - sas-bases/overlays/required/kustomizeconfig.yaml  # required for 0.6
    transformers:
      - sas-bases/overlays/network/ingress/security/transformers/product-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/ingress-tls-transformers.yaml   # TLS
      - sas-bases/overlays/network/ingress/security/transformers/backend-tls-transformers.yaml   # TLS
      - sas-bases/overlays/required/transformers.yaml
      - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
      - site-config/security/cert-manager-provided-ingress-certificate.yaml     # TLS
      - sas-bases/overlays/cas-server/auto-resources/remove-resources.yaml    # CAS-related
      #- sas-bases/overlays/scaling/zero-scale/phase-0-transformer.yaml
      #- sas-bases/overlays/scaling/zero-scale/phase-1-transformer.yaml
    configMapGenerator:
      - name: ingress-input
        behavior: merge
        literals:
          - INGRESS_HOST=tryit.${INGRESS_SUFFIX}
      - name: sas-shared-config
        behavior: merge
        literals:
          - SAS_SERVICES_URL=https://tryit.${INGRESS_SUFFIX}
      - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
        behavior: merge
        files:
          - SITEDEFAULT_CONF=site-config/sitedefault.yaml
    generators:
      - site-config/postgres/postgres-custom-config.yaml

    EOF"

    ```

## Build step

### Generate the manifest file

1. At this point, we are ready to generate the manifest, it may take a minute or two

    ```bash
    cd ~/project/deploy/lab
    kustomize build -o site.yaml

    ```

## Deploy step

### Apply the manifest file

Although you theoretically can apply "the entire content of the manifest" in a single command, doing so the first time has downsides.

As instructed in the documentation, we will break it down into consecutive steps.

1. First apply the parts that require Cluster-Wide permissions

    ```bash
    cd ~/project/deploy/lab

    ## apply
    kubectl -n lab apply  -f site.yaml --selector="sas.com/admin=cluster-wide"
    ```
    <details><summary>Click here to see the expected output</summary>
    ```
        ## Note the following output ending with 2 "unables":
        [cloud-user@pdcesx02074 lab]$ kubectl -n lab apply  -f site.yaml --selector="sas.com/admin=cluster-wide"
        customresourcedefinition.apiextensions.k8s.io/casdeployments.viya.sas.com created
        customresourcedefinition.apiextensions.k8s.io/pgclusters.crunchydata.com created
        customresourcedefinition.apiextensions.k8s.io/pgpolicies.crunchydata.com created
        customresourcedefinition.apiextensions.k8s.io/pgreplicas.crunchydata.com created
        customresourcedefinition.apiextensions.k8s.io/pgtasks.crunchydata.com created
        serviceaccount/pgo-backrest created
        serviceaccount/pgo-default created
        serviceaccount/pgo-pg created
        serviceaccount/pgo-target created
        serviceaccount/postgres-operator created
        serviceaccount/sas-cas-operator created
        serviceaccount/sas-cas-server created
        serviceaccount/sas-certframe created
        serviceaccount/sas-config-reconciler created
        serviceaccount/sas-data-server-utility created
        serviceaccount/sas-launcher created
        serviceaccount/sas-model-publish created
        serviceaccount/sas-prepull created
        serviceaccount/sas-rabbitmq-server created
        serviceaccount/sas-readiness created
        serviceaccount/sas-viya-backuprunner created
        role.rbac.authorization.k8s.io/pgo-backrest-role created
        role.rbac.authorization.k8s.io/pgo-pg-role created
        role.rbac.authorization.k8s.io/pgo-role created
        role.rbac.authorization.k8s.io/pgo-target-role created
        role.rbac.authorization.k8s.io/sas-cas-server created
        role.rbac.authorization.k8s.io/sas-certframe-role created
        role.rbac.authorization.k8s.io/sas-data-server-utility created
        role.rbac.authorization.k8s.io/sas-launcher created
        role.rbac.authorization.k8s.io/sas-model-publish created
        role.rbac.authorization.k8s.io/sas-prepull created
        role.rbac.authorization.k8s.io/sas-viya-backuprunner created
        role.rbac.authorization.k8s.io/sas-cas-operator created
        role.rbac.authorization.k8s.io/sas-config-reconciler created
        role.rbac.authorization.k8s.io/sas-rabbitmq-server created
        role.rbac.authorization.k8s.io/sas-readiness created
        clusterrole.rbac.authorization.k8s.io/sas-cas-operator created
        unable to recognize "site.yaml": no matches for kind "Pgcluster" in version "crunchydata.com/v1"
        unable to recognize "site.yaml": no matches for kind "CASDeployment" in version "viya.sas.com/v1alpha1"
    ```
    </details>


    ## wait for these resources to exist:
    kubectl -n lab wait --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd

    ```

1. Then apply the Cluster-Local level items:

    ```bash
    cd ~/project/deploy/lab
    kubectl -n lab apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune

    ```

1. And finally, the namespace-level objects:

    ```bash
    cd ~/project/deploy/lab
    kubectl -n lab apply  --selector="sas.com/admin=namespace" -f site.yaml --prune

    ```

    Doing this will create all required content in kubernetes and start up the process.

    Although the `  -n lab  ` is not required (because it was hard-coded throughout the `site.yaml` file), I strongly encourage you to make it a habit to always specify it.

<!--
1. If you receive messages similar to the following, rerun the apply command.

   ![apply_no_matches](img/apply_no_matches.png)
-->

## Store the URLs for later

1. No point in connecting yet, but let's store the URLs in a file, for later user

    ```bash
    NS=lab
    DRIVE_URL="https://$(kubectl -n ${NS} get ing sas-drive-app -o custom-columns='hosts:spec.rules[*].host' --no-headers)/SASDrive/"
    EV_URL="https://$(kubectl -n ${NS} get ing sas-drive-app -o custom-columns='hosts:spec.rules[*].host' --no-headers)/SASEnvironmentManager/"

    printf "\n* [Viya Drive (lab) URL (HTTP**S**)](${DRIVE_URL} )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (lab) URL (HTTP**S**)](${EV_URL} )\n\n" | tee -a /home/cloud-user/urls.md
    ```

1. Whenever you want to see the URLs for YOUR environment, execute:

    ```bash
    cat ~/urls.md
    ```

## watching the environment come up in tmux

1. This will kick off a tmux session called "lab_watch":

    ```sh
    #watch kubectl get pods -o wide -n lab

    SessName=lab_watch

    tmux new -s $SessName -d
    tmux send-keys -t $SessName "watch 'kubectl get pods -o wide -n lab | grep 0/ | grep -v Completed ' "  C-m
    tmux split-window -v -t $SessName
    tmux send-keys -t $SessName "watch -n 5 \"kubectl -n lab logs --selector='app.kubernetes.io/name=sas-readiness'  | tail -n 1 | jq \""  C-m
    tmux split-window -v -t $SessName
    tmux send-keys -t $SessName "kubectl wait -n lab --for=condition=ready pod --selector='app.kubernetes.io/name=sas-readiness'  --timeout=2700s"  C-m

    ```

1. And this will attach you to it, consider the following notes:

    * In this split screen view, you will see a list of pods at the top, and a few more things in the bottom part
    * The top part is only showing the pods with `0/` in the number of containers. So as time goes by, the list of pods will shrink. When they are all ` 1/1   Running`, your environment is likely ready.
    * The middle pane showing the `sas-readiness` pod make take ~5-8 minutes to show useful information, then it will show how many endpoints remain and show get to zero left when everything is up
    * It is unlikely that your environment will be ready in less than 30 minutes, so be patient. (When the "oldest" pod is about 30-35 minutes old, things should be settling down.)

    ```sh
    tmux attach -t $SessName
    ```

To get out of tmux, either press `Ctrl-B followed by D` or press `Ctrl-C` and type `exit` until the green line disappears.

<!--
## Stopping a part of the environment (not recommended)

This is probably not going to be necessary, but if you are using the Single-Image collection, the entire software stack might no fit.

If that is the case, many pods will be **Pending** for a long time.

To free up some space, you could stop part of environment.

```sh
## Scale down parts of the environment to save on resources
kubectl -n lab scale deployments --replicas=0 \
    compsrv                                        \
    sas-text-analytics                             \
    sas-text-cas-data-management                   \
    sas-text-categorization                        \
    sas-text-concepts                              \
    sas-text-parsing                               \
    sas-text-sentiment                             \
    sas-text-topics                                \
    sas-connect                                    \
    sas-conversation-designer-app                  \
    sas-data-mining-models                         \
    sas-data-mining-project-settings               \
    sas-data-mining-results                        \
    sas-data-mining-services                       \
    sas-data-quality-services                      \
    sas-device-management                          \
    sas-esp-operator

```

However, keep in mind that if you do this, many of the endpoints will stop responding, and so if you were to re-run gel_OKViya, your environment will never get all the way up to 95% ready.
 -->

## Validation

At this point, once the environment has finished booting up, you should be able to connect to SASDrive.

To see the URL you should use, execute:

```bash
cat ~/urls.md | grep tryit | grep Drive

```

Ctrl-Click on the URL to access Viya, accept the security risk from the self-signed certificate, and then log in with:

* User: `sasboot`
* Password: `lnxsas`

Once inside the Application, you should be able to navigate around.

However, keep in mind that you would not be able to use CAS or Compute when logged in as sasboot.

## Reset the default namespace

1. Make 'default' the default namespace again:

    ```sh
    kubectl config set-context --current --namespace=default
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
* [06 Deployment Steps / 06 031 Deploying a simple environment](/06_Deployment_Steps/06_031_Deploying_a_simple_environment.md)**<-- you are here**
* [06 Deployment Steps / 06 051 Deploying Viya with Authentication](/06_Deployment_Steps/06_051_Deploying_Viya_with_Authentication.md)
* [06 Deployment Steps / 06 061 Deploying in a second namespace](/06_Deployment_Steps/06_061_Deploying_in_a_second_namespace.md)
* [06 Deployment Steps / 06 071 Removing Viya deployments](/06_Deployment_Steps/06_071_Removing_Viya_deployments.md)
* [06 Deployment Steps / 06 215 Deploying a programing only environment](/06_Deployment_Steps/06_215_Deploying_a_programing-only_environment.md)
* [07 Deployment Customizations / 07 051 Adding a local registry to k8s](/07_Deployment_Customizations/07_051_Adding_a_local_registry_to_k8s.md)
* [07 Deployment Customizations / 07 052 Using mirrormgr to populate the local registry](/07_Deployment_Customizations/07_052_Using_mirrormgr_to_populate_the_local_registry.md)
* [07 Deployment Customizations / 07 053 Deploy from local registry](/07_Deployment_Customizations/07_053_Deploy_from_local_registry.md)
* [11 Azure AKS Deployment / 11 011 Creating an AKS Cluster](/11_Azure_AKS_Deployment/11_011_Creating_an_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 012 Performing Prereqs in AKS](/11_Azure_AKS_Deployment/11_012_Performing_Prereqs_in_AKS.md)
* [11 Azure AKS Deployment / 11 013 Deploying Viya 4 on AKS](/11_Azure_AKS_Deployment/11_013_Deploying_Viya_4_on_AKS.md)
* [11 Azure AKS Deployment / 11 014 Deleting the AKS Cluster](/11_Azure_AKS_Deployment/11_014_Deleting_the_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 015 Fast track with cheatcodes](/11_Azure_AKS_Deployment/11_015_Fast_track_with_cheatcodes.md)
* [11 Azure AKS Deployment / 11 131 CAS Customizations](/11_Azure_AKS_Deployment/11_131_CAS_Customizations.md)
* [11 Azure AKS Deployment / 11 132 Install monitoring and logging](/11_Azure_AKS_Deployment/11_132_Install_monitoring_and_logging.md)
<!-- endnav -->

<!--
Waiting for it to be up
```bash
if  [ "$1" == "wait" ]
then
    time gel_OKViya4 -n lab --wait -ps
fi
```
-->
