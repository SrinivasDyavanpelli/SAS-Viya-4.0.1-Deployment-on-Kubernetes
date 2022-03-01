![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Assess Readiness of Lab Environment

## Has the machine finished bootstrapping?

1. Execute the following command:

    ```sh
    tail -f /opt/raceutils/logs/$(hostname).bootstrap.log
    ```

    Wait for the last line to say:

    ```log
    03/16/20 18:15:38: Done running script /tmp/testclone/scripts/loop/GEL.99.TheEnd.sh
    ```

## Is Kubernetes ready?

1. Once connected to sasnode01, execute the following commands to see if Kubernetes is responding:

    ```sh
    kubectl cluster-info
    kubectl get nodes

    ```

1. You should see:

    ```log
    Kubernetes master is running at https://node3:6443
    CoreDNS is running at https://node3:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

    ```

    and

    ```log
    NAME        STATUS   ROLES                      AGE     VERSION
    intnode01   Ready    controlplane,etcd,worker   9m40s   v1.17.2
    intnode02   Ready    controlplane,etcd,worker   9m40s   v1.17.2
    intnode03   Ready    controlplane,etcd,worker   9m41s   v1.17.2
    intnode04   Ready    worker                     9m39s   v1.17.2
    intnode05   Ready    worker                     9m40s   v1.17.2
    ```

## If you are waiting for an environment to be up and running

If you chose one of the self-deploying options, you want to know if Viya is ready.
Otherwise, if you chose to deploy your own Viya, you can skip this check.

```sh
### Pick the namespace you are interested in checking
NS=gelenv-stable
time gel_OKViya4 -n ${NS} --wait -ps
```

This will display the current status of your environment and will keep cycling until 80% of your endpoints are working.
This can take between 15 minutes and 40 minutes for a fresh deployment.

When the endpoints are working, execute the following to display the URLs you can use:

```sh
cat ~/urls.md
```

Do a Ctrl-Click to open up those URLs in your browser.

## Navigation

<!-- startnav -->
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)
* [01 Introduction / 01 032 Assess Readiness of Lab Environment](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md)**<-- you are here**
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
