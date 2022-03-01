![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Booking a Lab Environment for the Workshop

## PRE-PROD Disclaimer

* DO NOT GET TOO ATTACHED! Things are in flux, and will go away.
* I'm happy for you (GEL Colleagues) to use this
* I welcome your feedback, but I may leave it on the back burner
* Put a watch on the project in [gitlab](https://gitlab.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes)
* Enter comments/complaints/requests as an [issue](https://gitlab.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes/issues) in the project and assign them to Erwan

## Important

* Some Lab Environments can take a significant amount of time to fully come online.
* You will probably be able to access your Servers before all the software on it is fully functional.
* Do make sure that you follow the instructions here to assess the state of [readiness](01_Introduction/02_Assess_Readiness_of_Lab_Environment.md) of your particular environment.

## Register yourself to be part of the STICExnetUsers group

* If you are not yet a member of the **STICExnetUsers** group, you need to join it.
  * [Click here](mailto:dlistadmin@wnt.sas.com?subject=Subscribe%20STICEXNETUsers) to prepare an email request to join **STICExnetUsers** group
  * Send the email as-is, without any changes
* Once the email is sent, you will be notified via email of the creation of the account.
* Your account membership should be updated and ready for use within 1 hour
* Sometimes, it takes much longer than 1 hour for this group membership to propagate through the network.
* To expedite the group membership, simply log out of the SAS network and log back in).
* Until the group membership change occurs, you won't be able reserve the environment.

## Choices

* Depending on your profile, you might be interested in 3 distinct Environments.
* They are:
  * A: Single Machine Kubernetes Cluster **with** Viya 4 already deployed
  * C1: Multi-Machine Kubernetes Cluster **without** Viya 4
  * C2: Multi-Machine Kubernetes Cluster **with** Viya 4 already deployed

<!--
  * B: Single Machine Kubernetes Cluster without Viya 4
-->

<!--
  * D: RACE Machine with Access to Kubernetes on Azure AKS
 -->

Do make sure you know which environment you need before reserving it.

## Environment booking:

You can change the Start and Stop date for the environment, but **do not** change the text in the Comments field!

### A: Single Machine Kubernetes Cluster with Viya 4 already deployed

* [Book](http://race.exnet.sas.com/Reservations?action=new&imageId=226681&imageKind=C&comment=Viya%204%20-%20Single%20Machine%20Kubernetes%20with%20_AUTODEPLOY-GELENV_&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0) the single machine with AUTODEPLOY

<!--
### B: Single Machine Kubernetes Cluster without Viya 4

* [Book](http://race.exnet.sas.com/Reservations?action=new&imageId=226681&imageKind=C&comment=Viya%204%20-%20Single%20Machine%20Kubernetes&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0) the single machine
 -->

### C1: Multi-Machine Kubernetes Cluster without Viya 4

* [Book](http://race.exnet.sas.com/Reservations?action=new&imageId=220997&imageKind=C&comment=Viya%204%20-%20Multi%20Machine&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0) the Blank 5-machine collection (Kubernetes-Only)

### C2: Multi-Machine Kubernetes Cluster with Viya 4

* [Book](http://race.exnet.sas.com/Reservations?action=new&imageId=220997&imageKind=C&comment=Viya%204%20-%20Multi%20Machine%20_AUTODEPLOY-GELENV_&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0) the "autodeploy" 5-machine collection (Kubernetes and Viya 4)

<!--
### D: RACE Machine with Access to Kubernetes on Azure AKS

This is only available during live teach of the workshop.

* any of the above will do, but the single-machine is best:
* [Book](http://race.exnet.sas.com/Reservations?action=new&imageId=226681&imageKind=C&comment=Viya%204%20-%20Single%20Machine&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0) the single machine
-->

### D1: Exclusively for Mr Mark Thomas

* [Book D1](http://race.exnet.sas.com/Reservations?action=new&imageId=291499&imageKind=C&comment=Viya4%20-%20Shared%20coll%20_AUTODEPLOY-GELENV_%20Shared%20coll&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=0) the shared collection

## Environment access

Each environment (RACE Collection) is made up of:

* One Windows Client Machine
* 5 Centos Linux Machines

* You MUST connect to the Windows Client machine first
  * u: `.\student`
  * p: `Metadata0`
* From that Windows Jump Host, you can access your Linux machines which is defined as sasnode01 in MobaXTerm.
  * u: `cloud-user`
  * p: `lnxsas`

### OS Credentials

The most commonly needed OS credentials for the servers in the collection are:

| Machine    | User:      | Password:   | Connection type |
|------------|------------|-------------|-----------------|
| Linux      | `cloud-user` | `lnxsas`      | SSH             |
| Windows    | `.\student`  | `Metadata0`   | RDP             |

### Viya Credentials

The credentials to access Viya are:

| User:      | Password:       |
|------------|-----------------|
| `sasboot`  | `lnxsas`        |
| `sasadm`   | `lnxsas`        |
| `geladm`   | `lnxsas`        |
| `alex`     | `lnxsas`        |

### Readiness

* Do make sure that you follow the instructions here to assess the state of [readiness](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md) of your particular environment.

<!--
* Single machine [book](http://race.exnet.sas.com/Reservations?action=new&imageId=226681&imageKind=C&comment=_AUTODEPLOY_%20Deploy%20Viya%204%20-%20Single%20Machine&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=5&admin=yes)

* 5-Machine Collection [book](http://race.exnet.sas.com/Reservations?action=new&imageId=220997&imageKind=C&comment=Deploy%20Viya%204%20-%20Multi%20Machine&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=5&admin=yes)

* 5-Machine Collection [book](http://race.exnet.sas.com/Reservations?action=new&imageId=220997&imageKind=C&comment=_BREAK_%20Deploy%20Viya%204%20-%20Multi%20Machine&purpose=PST&sso=PSGEL255&schedtype=SchedTrainEDU&startDate=now&endDateLength=5&admin=yes)

1429294
is replaced by:
BLANK CENTOS - Viya 4
1434067

single-image->2machine coll
5-machine coll ->6 machine coll

Mike's windows image.
1446668

Erwan's Linux image 1434067
Erwan's Windows Image: 1451175

New windows image (2020.03.19): 1463661
coll: 226681
update  node1-> sasnode01

k3s:
coll 226681
lin: 1434067
win: 1463661

k8s:
coll: 220997
lin: 1434067
win: 1463661

New Windows machine:
1566991

Golding images.
re-do windows machine:
 - update VS code
 - update Chrome
 - install lens

Shared Coll: 291499
    11 * linux image


 -->

## Navigation

<!-- startnav -->
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)**<-- you are here**
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
* [07 Deployment Customizations / 07 053 Deploy from local registry](/07_Deployment_Customizations/07_053_Deploy_from_local_registry.md)
* [11 Azure AKS Deployment / 11 011 Creating an AKS Cluster](/11_Azure_AKS_Deployment/11_011_Creating_an_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 012 Performing Prereqs in AKS](/11_Azure_AKS_Deployment/11_012_Performing_Prereqs_in_AKS.md)
* [11 Azure AKS Deployment / 11 013 Deploying Viya 4 on AKS](/11_Azure_AKS_Deployment/11_013_Deploying_Viya_4_on_AKS.md)
* [11 Azure AKS Deployment / 11 014 Deleting the AKS Cluster](/11_Azure_AKS_Deployment/11_014_Deleting_the_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 015 Fast track with cheatcodes](/11_Azure_AKS_Deployment/11_015_Fast_track_with_cheatcodes.md)
* [11 Azure AKS Deployment / 11 131 CAS Customizations](/11_Azure_AKS_Deployment/11_131_CAS_Customizations.md)
* [11 Azure AKS Deployment / 11 132 Install monitoring and logging](/11_Azure_AKS_Deployment/11_132_Install_monitoring_and_logging.md)
<!-- endnav -->


