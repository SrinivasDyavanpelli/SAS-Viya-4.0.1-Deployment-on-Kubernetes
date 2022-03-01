![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploying in a second namespace

* [Create the namespace](#create-the-namespace)
* [Deploy GELLDAP into it](#deploy-gelldap-into-it)
* [Copy the files](#copy-the-files)
* [Edit the files that have been copied:](#edit-the-files-that-have-been-copied)
* [Build](#build)
* [Apply](#apply)
* [Waiting for it to boot](#waiting-for-it-to-boot)
* [URLs for Dev environment](#urls-for-dev-environment)
* [Validating](#validating)
* [Pending pod](#pending-pod)
* [Navigation](#navigation)

This hands-on will allow you to deploy an identical environment in another namespace.

## Create the namespace

```bash

kubectl delete ns dev
kubectl create ns dev

```

## Deploy GELLDAP into it

```bash
cd ~/project/gelldap/
kustomize build ./no_TLS/ | kubectl -n dev apply -f -

```

## Copy the files

Copying the files is not the "best" way, but it's the simplest, so for now, let's just copy the important files from lab into dev.

```bash
rm -rf  ~/project/deploy/dev
mkdir -p  ~/project/deploy/dev
cp -rp ~/project/deploy/lab/kustomization.yaml ~/project/deploy/dev/
cp -rp ~/project/deploy/lab/sas-bases ~/project/deploy/dev/sas-bases
cp -rp ~/project/deploy/lab/site-config ~/project/deploy/dev/site-config
cp -rp ~/project/deploy/lab/*.tgz ~/project/deploy/dev/
ls -al  ~/project/deploy/dev/

```

## Edit the files that have been copied:

1. Indent works better

    ```bash
    ## change the namespace
    ansible localhost \
    -m lineinfile \
    -a  "dest=~/project/deploy/dev/kustomization.yaml \
        regexp='^namespace:' \
        line='namespace: dev' \
        state=present \
        backup=yes " \
        --diff

    ## change the Ingress
    ansible localhost \
    -m replace \
    -a  "dest=~/project/deploy/dev/kustomization.yaml \
        regexp='tryit' \
        replace='devvit' \
        backup=yes " \
        --diff

    ```

## Build

```bash
cd ~/project/deploy/dev/
kustomize build -o site.yaml

```

and then:

```sh
# compare with the other file
icdiff -H ~/project/deploy/lab/site.yaml ~/project/deploy/dev/site.yaml

```

## Apply

```bash
cd ~/project/deploy/dev/
kubectl -n dev apply  -f site.yaml

```

## Waiting for it to boot

```sh
time gel_OKViya4 -n dev  --wait --pod-status
# or
kubectl wait -n dev --for=condition=ready pod --selector='app.kubernetes.io/name=sas-readiness'  --timeout=2700s
```

## URLs for Dev environment

1. No point in connecting yet, but let's store the URLs in a file, for later user

    ```bash

    NS=dev
    DRIVE_URL="https://$(kubectl -n ${NS} get ing sas-drive-app -o custom-columns='hosts:spec.rules[*].host' --no-headers)/SASDrive/"
    EV_URL="https://$(kubectl -n ${NS} get ing sas-drive-app -o custom-columns='hosts:spec.rules[*].host' --no-headers)/SASEnvironmentManager/"


    printf "\n* [Viya Drive (dev) URL (HTTP**S**)](${DRIVE_URL} )\n\n" | tee -a /home/cloud-user/urls.md
    printf "\n* [Viya Environment Manager (dev) URL (HTTP**S**)](${EV_URL} )\n\n" | tee -a /home/cloud-user/urls.md
    ```

1. Whenever you want to see the URLs for YOUR environment, execute:

    ```bash
    cat ~/urls.md
    ```

## Validating

You should be able to log into the Dev environment independently of Lab. (using the URLs above).

It is likely that Dev will be ready faster than Lab was, because the images have already been cached on many machines. However, you have now 2 Viyas running in parallel, so there are less resources available to the second one.

You can perform the same type of validation.

## Pending pod

You will notice that one of the pods (`sas-cas-server-default-controller`) in the DEV namespace will never run, and be Pending forever.

This is to be expected and is due to our use of CAS AutoResources.

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
* [06 Deployment Steps / 06 061 Deploying in a second namespace](/06_Deployment_Steps/06_061_Deploying_in_a_second_namespace.md)**<-- you are here**
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
    time gel_OKViya4 -n dev --wait -ps
fi
```
-->
