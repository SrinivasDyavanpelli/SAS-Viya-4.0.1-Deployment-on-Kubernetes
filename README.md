![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

![under construction](2020-10-28-11-40-16.png)

# PSGEL255: Deploying Viya 4.0.1 on Kubernetes

This workshop will try to teach teach you:

* Just enough Kubernetes to understand what you're doing
* How to assess the fitness of the Kubernetes cluster you are given
* How to deploy your first, basic, Viya 4 deployment
* How to configure and re-deploy with:
  * Authentication
  * Persistent volumes
  * Access engines
* How to troubleshoot some common deployment issues

## Target audience

* Anyone whose job entails helping a customer stand up Viya 4
  * SAS Employees, in Face-to-face workshops
  * SAS Employees, through the VLE
  * SAS Partners, through the external VLE

## Lab environment

* Options
  * Azure Kubernetes shared cluster (as big as needed)
  * RACE multi-machine collection (6*30GB)
* Uses
  * Azure gives us a Production-grade cluster at very low price.
  * The RACE collection enables more advanced use cases (losing node, etc...) and constantly running shared environments
  * RACE-based HW will need both a VMWare and an AWS/Azure version in case we run out of HW?

## Structure of content and materials

All slides: [This Sharepoint Location](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides?csf=1&web=1&e=mF6RDX)
All Hands-On: [This Gitlab Location](https://gitlab.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes)

### 01 Introduction

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/01_Introduction?csf=1&web=1&e=XDGncw)
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)
* [01 Introduction / 01 032 Assess Readiness of Lab Environment](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md)

### 02 Kubernetes and Containers Fundamentals

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/02_Kubernetes_and_Containers_Fundamentals?csf=1&web=1&e=Hoy9hG)
* [02 Kubernetes and Containers Fundamentals / 02 131 Learning about Namespaces](/02_Kubernetes_and_Containers_Fundamentals/02_131_Learning_about_Namespaces.md)

### 03 Viya 4 Software Specifics

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/03_Viya_4_Software_Specifics?csf=1&web=1&e=uoKSn3)
* [03 Viya 4 Software Specifics / 03 011 Looking at a Viya 4 environment with Visual Tools DEMO](/03_Viya_4_Software_Specifics/03_011_Looking_at_a_Viya_4_environment_with_Visual_Tools_DEMO.md)
* [03 Viya 4 Software Specifics / 03 031 Create your own Viya order](/03_Viya_4_Software_Specifics/03_031_Create_your_own_Viya_order.md)

### 04 Pre-Requisites

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/04_Pre-Requisites?csf=1&web=1&e=ObawuW)
* [04 Pre Requisites / 04 061 Pre Requisites automation with ARKCD](/04_Pre-Requisites/04_061_Pre-Requisites_automation_with_ARKCD.md)

### 05 Deployment tools

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/05_Deployment_tools?csf=1&web=1&e=ZHphnM)
* [05 Deployment tools / 05 121 Setup a Windows Client Machine](/05_Deployment_tools/05_121_Setup_a_Windows_Client_Machine.md)

### 06 Deployment Steps

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/06_Deployment_Steps?csf=1&web=1&e=NCHMal)
* [06 Deployment Steps / 06 031 Deploying a simple environment](/06_Deployment_Steps/06_031_Deploying_a_simple_environment.md)
* [06 Deployment Steps / 06 051 Deploying Viya with Authentication](/06_Deployment_Steps/06_051_Deploying_Viya_with_Authentication.md)
* [06 Deployment Steps / 06 061 Deploying in a second namespace](/06_Deployment_Steps/06_061_Deploying_in_a_second_namespace.md)
* [06 Deployment Steps / 06 071 Removing Viya deployments](/06_Deployment_Steps/06_071_Removing_Viya_deployments.md)
* [06 Deployment Steps / 06 215 Deploying a programing only environment](/06_Deployment_Steps/06_215_Deploying_a_programing-only_environment.md)

### 07 Deployment Customizations

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/07_Deployment_Customizations?csf=1&web=1&e=EsfH4e)
* [07 Deployment Customizations / 07 051 Adding a local registry to k8s](/07_Deployment_Customizations/07_051_Adding_a_local_registry_to_k8s.md)
* [07 Deployment Customizations / 07 052 Using mirrormgr to populate the local registry](/07_Deployment_Customizations/07_052_Using_mirrormgr_to_populate_the_local_registry.md)
* [07 Deployment Customizations / 07 053 Deploy from local registry](/07_Deployment_Customizations/07_053_Deploy_from_local_registry.md)

### 08 Recommended practices

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/08_Recommended_practices?csf=1&web=1&e=LIcQ5o)

### 09 Validation

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/09_Validation?csf=1&web=1&e=tWgk8f)

### 10 Troubleshooting

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/10_Troubleshooting?csf=1&web=1&e=1hoJbz)

### Managed Kubernetes Services

* [Slides](https://sasoffice365.sharepoint.com/:f:/r/sites/GEL/GELWS/Shared%20Documents/PSGEL255/Slides/11_Managed_Kubernetes_Services?csf=1&web=1&e=TbLN4W)
* [11 Azure AKS Deployment / 11 011 Creating an AKS Cluster](/11_Azure_AKS_Deployment/11_011_Creating_an_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 012 Performing Prereqs in AKS](/11_Azure_AKS_Deployment/11_012_Performing_Prereqs_in_AKS.md)
* [11 Azure AKS Deployment / 11 013 Deploying Viya 4 on AKS](/11_Azure_AKS_Deployment/11_013_Deploying_Viya_4_on_AKS.md)
* [11 Azure AKS Deployment / 11 014 Deleting the AKS Cluster](/11_Azure_AKS_Deployment/11_014_Deleting_the_AKS_Cluster.md)**<-- you are here**
* [11 Azure AKS Deployment / 11 015 Fast track with cheatcodes](/11_Azure_AKS_Deployment/11_015_Fast_track_with_cheatcodes.md)
* [11 Azure AKS Deployment / 11 131 CAS Customizations](/11_Azure_AKS_Deployment/11_131_CAS_Customizations.md)
* [11 Azure AKS Deployment / 11 132 Install monitoring and logging](/11_Azure_AKS_Deployment/11_132_Install_monitoring_and_logging.md)

## Where to go next



<!--

folders:

grep '### ' README.md | grep -v grep | sed  "s|###\ ||g" | sed 's| |_|g'

for fol in $(grep '### ' README.md | grep -v grep | sed  "s|###\ ||g" | sed 's| |_|g'  )
do
    #echo $fol
    echo mkdir $fol
done

HO:

grep '.md' README.md | grep -v grep | sed  "s|* HO: ||g" | sed 's| |_|g'



Chapters of slides:

* re-cycle "concepts" slides from 3.5
* need to be added: kustomize / persistence
* containers
* kubernetes

assume k8s knowledge?

shared jumphost?

* Connect to shared machine.
* Create your own OS user (gatedemo001 etc..)
* Create your own Kubernetes Account
* Create your own Kubernetes Namespace
* Start working in your "walled garden"
* Deploy OpenLDAP
* Deploy PHPLDAPADMIN
* Configure Persistence for OpenLDAP
* Configure Ingress
* Scale things back and forth
* Intro to Kustomize?
* Exec into a container

* Assess kubernetes fitness for purpose
  * size
  * spare capacity
  * restrictions on namespace
  * ideas on disk IO?
  * ingress type
  * ingress test

* Private/public registries
  * Container image mirroring

* Files management:
  * Kustomize.tgz
  * Kustomize CLI
    * Manifests
    * Overlays
    * Base

* debugging
  * Crashloops
  * describe
  * testing image access?
  * Exec in and debug

* ELK stack
  * ELK
  * Grafana etc.

* Persistence
* Authentication
* Ingress

* Migration from 3.5 (Gerry)
* Viya 4.0.1 - can and can'ts

* -->
