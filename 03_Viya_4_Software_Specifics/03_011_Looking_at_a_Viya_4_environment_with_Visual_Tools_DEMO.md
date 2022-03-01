![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Accessing a Viya 4 environment with Visual Tools

This is not a Hands-On. This is a demo script.

These are the steps in support of a Demo.

The Teacher is supposed to go through these steps in order to show the class.

The tools shown in this demo may or may not be available at a customer site.

## Booting up the environment

This can only be done on the Multi-Machine Collection, and not on the single machine one.

## Deploying Rancher

Rancher can be installed in this environment by running the following:

```bash
bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.12.B.Rancher.sh deploy

```

## Kick off the deployment

1. Before anything else, kick off the deployment:

    ```bash
    bash  ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/01_Introduction/01_000_gelenv_order.sh
    ```

1. Wait for that command to complete wait for it.

## Open the Web Apps

* Display the environment's URL.

    ```bash
    cat ~/urls.md | grep -E 'gelenv|rancher'

    ```

### Rancher

* [ ] Open Rancher
* [ ] Choose password (`lnxsas`)
* [ ] Confirm URL
* [ ] Wait for cluster to be added
* [ ] Show total Cluster capacity
* [ ] Click on **Nodes** to show the make up of the cluster
* [ ] Click on Cluster to show the Gauges
* [ ] Go to **Tools** / **Monitoring**, then scroll to the bottom and click **Enable**.
* [ ] In the **Cluster** view, explain the difference between **Used** and **Reserved**.
* [ ] When Grafana shows up, show some of the diagrams

### Use lens as well

* [ ] Copy the content of `cat ~/.kube/config_portable`
* [ ] Open Lens
* [ ] Add new cluster
* [ ] Paste

<!--
### Weave

* [ ] Open Weave
* [ ] Continue in spite of TLS Warning
* [ ] Start with "Hosts" view
  * [ ] Show the host's virtual Network
* [ ] Go to the Pod view
  * [ ] Graph is overwhelming. Change to table.
  * [ ] Point out Namespace Column
  * [ ] Pod Name ends is a random string
  * [ ] Search for pod called Studio
  * [ ] Choose **sasstudiov**
  * [ ] Show the **Get Logs** icon
  * [ ] Show the **Describe** icon
* [ ] Click the **Delete** icon and confirm
  * [ ] Show how the pod comes back, with a new name, and with a new IP
* [ ] Scale it out in **Controllers** menu
  * [ ] Notice many pods, and many IPs.
* If it's available, go to the Container View, and show how to Exec into one container.
* Show Storage (available in the faded menu bottom left)
 -->

### Accessing the environment itself

* [ ] By then it should be finished deploying.
* [ ] Access SASDrive and navigate


## Navigation

<!-- startnav -->
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)
* [01 Introduction / 01 032 Assess Readiness of Lab Environment](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md)
* [02 Kubernetes and Containers Fundamentals / 02 131 Learning about Namespaces](/02_Kubernetes_and_Containers_Fundamentals/02_131_Learning_about_Namespaces.md)
* [03 Viya 4 Software Specifics / 03 011 Looking at a Viya 4 environment with Visual Tools DEMO](/03_Viya_4_Software_Specifics/03_011_Looking_at_a_Viya_4_environment_with_Visual_Tools_DEMO.md)**<-- you are here**
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
