![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

<!--
```bash
nohup kubectl delete ns lab &
nohup kubectl delete ns dev &

```
 -->

# Removing Viya deployments

At this point, we are simply going to walk through progressively removing our Viya deployment.

* [Stopping all the pods](#stopping-all-the-pods)
* [Deleting kubernetes artifacts inside a namespace](#deleting-kubernetes-artifacts-inside-a-namespace)
* [Deleting all artifacts inside a namespace](#deleting-all-artifacts-inside-a-namespace)
* [Deleting the namespace itself](#deleting-the-namespace-itself)
* [Navigation](#navigation)

## Stopping all the pods

1. You might think that deleting the pods will do the trick:

    ```sh
    kubectl -n lab get pods
    kubectl -n lab delete pods --all
    kubectl -n lab get pods
    ```

1. But as you'll see, they will terminate and then be restarted.
1. That's because we have other kubernetes objects (deployments, statefulsets, operators) that ensure there is always 1 replica of each pod running.
1. So to stop all the "running" pods for good, you would have to run:

    ```sh
    # run these commands one by one and see the impact it has:

    kubectl -n lab scale deployments --all --replicas=0

    kubectl -n lab scale statefulsets --all --replicas=0

    kubectl -n lab delete casdeployment --all

    kubectl -n lab delete jobs --all
    ```

1. At this point all your pods have been stopped.

1. You could restart your environment still, simply by re-applying your manifest

    ```sh
    kubectl -n lab apply -f ~/project/deploy/lab/site.yaml

    ```

1. However, because we've done a scale to zero, and because the number of replicas is not part of the manifest, we also have to do a scale to 1

    ```sh
    kubectl -n lab scale deployments --all --replicas=1

    kubectl -n lab scale statefulsets --all --replicas=1

    ```

## Deleting kubernetes artifacts inside a namespace

1. Now, we start actively removing things from a namespace.
1. First instinct will be to do a delete all:

    ```sh
    kubectl -n lab delete all --all

    ```

1. While this is certainly going to remove a lot of things, it will be far from complete.
1. For example, "all" does not include all artifacts:

    ```sh
    kubectl -n lab get ing,pvc,cm,secrets,casdeployments

    ```

1. So to clean out things further, one might want to use the same manifest we used to create things, and use it to delete, like the following:

    ```sh
    kubectl -n lab delete -f ~/project/deploy/lab/site.yaml

    ```

1. So, to help it along a bit more, we migh want to do:

    ```sh
    kubectl -n lab  delete secrets -l vendor=crunchydata
    kubectl -n lab  delete deployment -l vendor=crunchydata
    kubectl -n lab  delete service -l vendor=crunchydata
    kubectl -n lab  delete cm -l vendor=crunchydata
    kubectl -n lab  delete pvc -l vendor=crunchydata
    ```

1. But even that will still leave some things behind.

    ```sh
    kubectl -n lab get events
    ```

1. So check out the next section

## Deleting all artifacts inside a namespace

check out this snippet: <https://gitlab.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes/snippets/1046>

So to run it:

```sh
# assign a default value to the namespace
NS=${NS:-lab}
echo "chosen namespace is: ${NS}"

remove_viya_from_ns () {
    if  [ "$1" == "" ]; then
        printf "Please add a namespace\nExiting\n"
    else
        ## don't delete the events, that takes too long
        items_to_delete=$(kubectl api-resources --namespaced=true --verbs=delete -o name | grep -v event | tr "\n" "," | sed -e 's/,$//')

        #viya_filters='-l sas.com/deployment=sas-viya,vendor=crunchydata'

        printf "\n The delete command would therefore be:\n--------\n kubectl -n $1 delete  $items_to_delete ${viya_filters} \n------\n"
        read -n1 -rsp $'Press any key to continue and hollow-out the namespace (or press Ctrl+C to exit)...\n'
        #kubectl -n $1 delete --all $items_to_delete
        #kubectl -n $1 delete $items_to_delete ${viya_filters}
        kubectl -n $1 delete $items_to_delete -l sas.com/deployment=sas-viya
        kubectl -n $1 delete $items_to_delete -l vendor=crunchydata
    fi
}

# sample exec:
remove_viya_from_ns ${NS}

```

This command should take care of those leftover items in the namespace, but is also dangerous.

## Deleting the namespace itself

Of course, this is the easy way out, and that's why I left it for last.

If you can delete the namespace, it's the easiest and cleanest way to delete Viya. However, think about the implications:

* can you re-create that namespace? or are you going to have to ask someone else to re-create it for you?
* Are there other (non-Viya) things in that namespace? Will the customer be happy if they disappear?

Assuming we are all good with that, you can simply run:

```sh
kubectl delete ns lab

```

and we might as well also delete the other namespace we've used:

```sh
kubectl delete ns dev

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
* [06 Deployment Steps / 06 071 Removing Viya deployments](/06_Deployment_Steps/06_071_Removing_Viya_deployments.md)**<-- you are here**
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
