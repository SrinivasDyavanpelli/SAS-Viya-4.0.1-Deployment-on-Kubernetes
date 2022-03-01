![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

** THIS IS A DRAFT **

# Creating a local container registry

* [Installing Harbor](#installing-harbor)
  * [Update the URLs for Harbor](#update-the-urls-for-harbor)
* [Logging in and creating a new repository](#logging-in-and-creating-a-new-repository)
* [code to auto-create this](#code-to-auto-create-this)
* [Navigation](#navigation)

## Installing Harbor

1. First you should create a namespace to hold Harbor

    ```bash
    kubectl create ns harbor

    ```

1. then, you should ...

    ```bash

    helm repo add harbor https://helm.goharbor.io

    helm install my-harbor harbor/harbor \
        --namespace harbor \
        --set expose.type=ingress \
        --set expose.tls.enabled=true \
        --set expose.ingress.hosts.core=harbor.$(hostname -f) \
        --set persistence.enabled=true \
        --set clair.enabled=true \
        --set externalURL=https://harbor.$(hostname -f)/ \
        --set harborAdminPassword=lnxsas \
        --set persistence.persistentVolumeClaim.registry.size=55Gi

    # printf "* [Harbor URL](https://harbor.$(hostname -f)/)\n" \
    #  | tee -a ~/urls.md
    ```

1. wait for all pods in namespace to be ready:

    ```bash
    waitforpods () {
        PODS_NOT_READY=99
        while [ "${PODS_NOT_READY}" != "0" ]
        do
            PODS_NOT_READY=$(kubectl get pods -n $1 --no-headers | grep -v Completed | grep -E -v '1/1|2/2' | wc -l)
            printf "\n\n\nWaiting for these ${PODS_NOT_READY} pods to be Running: \n"
            kubectl get pods -n $1 --no-headers | grep -v Completed | grep -E -v '1/1|2/2'
            sleep 5
        done
        printf "All pods in namespace $1 seem to be ready \n\n\n\n"
    }

    waitforpods harbor
    ```

1. Now, test that we can use it:

    ```bash
    docker login harbor.$(hostname -f):443 -u admin -p lnxsas


    docker pull centos:7
    docker tag centos:7 harbor.$(hostname -f):443/library/centos:7
    docker push  harbor.$(hostname -f):443/library/centos:7
    ```

### Update the URLs for Harbor

1. Adding the harbor URLs to the `~/urls.md/ file:

    ```bash
    printf "\n* [Local Harbor Registry URL (HTTPS)](https://harbor.$(hostname -f)/ ) (u=admin,p=lnxsas)\n\n" | tee -a /home/cloud-user/urls.md

    ```

## Logging in and creating a new repository

In order to get familiar with Harbor, you might want to do the following steps "manually" first. (after that, some automated code will re-do the same thing for you again)

Using your web browser, log into Harbor and:

* create a project called **viya_manual**
* create a robot account called **viya_manual**

* the real account and credentials will be done automatically in the next step.

## code to auto-create this

for a scripted way of doing the same, check out those instructions:

<https://gitlab.sas.com/adbull/documentation/-/blob/master/mirror_harbor.md>

so:

```bash
# credits to Adam Bullock for this elegant piece of work

export PROJECTNAME=viya
HARBORADM=admin
HARBORPASS=lnxsas
export HARBOR_ING=$(kubectl -n harbor get ing  my-harbor-harbor-ingress \
                -o custom-columns='host:spec.rules[*].host' --no-headers)
ROBOUSER=viya

curl -k -X POST "https://$HARBOR_ING/api/v2.0/projects" \
    -u $HARBORADM:$HARBORPASS \
    -H 'Content-Type: application/json' \
    --data '{"project_name": "'"$PROJECTNAME"'"}'

PROJECT_ID=$(curl -k -s -X GET "https://$HARBOR_ING/api/v2.0/projects?name=$PROJECTNAME" \
    -H "accept: application/json" -u $HARBORADM:$HARBORPASS | \
    jq '.[] |  select(.name=="'"$PROJECTNAME"'") | .project_id')

curl -k -s -X POST "https://$HARBOR_ING/api/v2.0/projects/$PROJECT_ID/robots" \
    -u $HARBORADM:$HARBORPASS \
    -H 'Content-Type: application/json' \
    --data '{
    "access": [
        {
        "action": "push",
        "resource": "/project/'$PROJECT_ID'/repository"
        }
    ],
    "name": "'$ROBOUSER'",
    "description": "Used for viya"
    }' -k -o ~/exportRobot.json

```

The created file (`~/exportRobot.json`) contains the credentials that allow the `robot$viya` user to access the newly created **viya** project inside harbor.

Open the Harbor web interface to confirm the project exists.

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
* [07 Deployment Customizations / 07 051 Adding a local registry to k8s](/07_Deployment_Customizations/07_051_Adding_a_local_registry_to_k8s.md)**<-- you are here**
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
