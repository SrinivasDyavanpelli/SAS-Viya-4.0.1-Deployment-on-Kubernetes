![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Learning about namespaces

* [Introduction](#introduction)
* [What namespaces do I have?](#what-namespaces-do-i-have)
* [Creating a namespace](#creating-a-namespace)
  * [The quick way](#the-quick-way)
  * [The longer way](#the-longer-way)
* [Declarative vs Imperative](#declarative-vs-imperative)
* [Describing the Namespace](#describing-the-namespace)
* [Deleting the Namespace](#deleting-the-namespace)
  * [fast](#fast)
  * [slow](#slow)
* [Quiz](#quiz)
* [Navigation](#navigation)

## Introduction

This series of exercises will make you learn about namespaces. By the end of it, you should be able to answer the quiz.

## What namespaces do I have?

to see the list of available namespaces, you can type one of the following commands:

* `kubectl get namespace`
* `kubectl get namespaces`
* `kubectl get ns`

Note the flexibility above: the 3 names are synonyms and will yield the same results.

## Creating a namespace

### The quick way

1. The fastest way to create a namespace is to type:

    ```bash
    kubectl create ns hare

    ```

1. If you check your list of namespaces, you'll see a new namespace, created a few seconds ago.

1. While this is acceptable, there is a downside: if you try the same "Imperative" command again, you'll get an error message.

    ```bash
    kubectl create ns hare

    ```

    will now result in:

    ```log
    Error from server (AlreadyExists): namespaces "hare" already exists
    ```

### The longer way

1. Instead of issuing an ad-hoc command, we will now create a manifest file describing what we want want our namespace to be:

    ```bash
    tee  /tmp/turtle_namespace.yaml > /dev/null << "EOF"
    ---
    apiVersion: v1
    kind: Namespace
    metadata:
      name: turtle
      labels:
        name: "my_turtle"
        owner: "sas.com"
    EOF
    ```

1. After reviewing the content of the above file, issue this command to get kubernetes to create this namespace

    ```bash
    kubectl apply -f /tmp/turtle_namespace.yaml

    ```

1. Now review again your list of namespaces. You should be able to see both the `turtle` and the `hare` namespaces

1. Note however that re-running the same command again:

    ```bash
    kubectl apply -f /tmp/turtle_namespace.yaml

    ```

    results in:

    ```log
    namespace/turtle unchanged
    ```

    which is a lot cleaner.

## Declarative vs Imperative

Thanks to Nicolas Sigal for this suggestion.

* "Imperative" is a command - like "create 42 widgets"
* "Declarative" is a statement of the desired end result - like "I want 42 widgets to exist"

In the above, we used the `kubectl apply` syntax. That is the **Declarative form**. We could also have used the **Imperative** form, if we had used `kubectl create` instead. However, doing so in the Imperative form would once again result in an error message if you did it more than once.

## Describing the Namespace

In order to get more detailed info about the namespace you can issue the describe command:

```bash
kubectl describe ns hare turtle

```

Notice that one has more labels than the other.

## Deleting the Namespace

### fast

```bash
kubectl delete ns hare

```

### slow

```bash
kubectl delete -f /tmp/turtle_namespace.yaml

```

## Quiz

1. If I deleted the file ( `rm /tmp/turtle_namespace.yaml` ), would it also have deleted the namespace?

    <details><summary>answer:</summary>

    * No. Once the information is stored in Kubernetes, the file that was used to load it in no longer matters. However, you should keep it around in case you need to edit things in the future
    </details>


1. How many different namespaces can I create in a kubernetes cluster? (hint: use google)

    <details><summary>answer:</summary>

    * Either "enough" or "as many as you are ever going to need". For more info, [google it](https://lmgtfy.com/?q=kubernetes+maximum+number+of+namespaces)

    </details>

1. Can 2 kubernetes clusters share a common namespace?

    <details><summary>answer:</summary>

    * No. Two distinct Kubernetes cluster will not have anything in common with one another. And therefore, you could use the same exact Namespace **name** in both Kubernetes.

    </details>


1. When choosing the **name** of the namespace, are there do's and dont's? (hint: try creating a namespace with weird characters, spaces, etc...)

    <details><summary>answer:</summary>

    * There are. For example, `kubectl create ns turtle_hare` will result in:

    ```log
    The Namespace "turtle_hare" is invalid:
    metadata.name: Invalid value: "turtle_hare":
    a DNS-1123 label must consist of lower case alphanumeric characters or '-', and must start and end with an alphanumeric character (e.g. 'my-name',  or '123-abc', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?')
    ```

    </details>


1. What is the main use for Namespaces?

    <details><summary>answer:</summary>

    * Namespaces are used a lot. They serve the purpose of grouping things together, and separating them from each other. They let us carve up a Kubernetes cluster into chunks that can be more easily administered and managed.

    </details>

1. Does deleting a namespace delete things that might be stored inside of it?

    <details><summary>answer:</summary>

    * Yes. Which is great.

    </details>

1. How many distinct Viya environments will I be able/allowed to deploy inside of a single namespace?

    <details><summary>answer:</summary>

    * One (1).

    </details>

## Navigation

<!-- startnav -->
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)
* [01 Introduction / 01 032 Assess Readiness of Lab Environment](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md)
* [02 Kubernetes and Containers Fundamentals / 02 131 Learning about Namespaces](/02_Kubernetes_and_Containers_Fundamentals/02_131_Learning_about_Namespaces.md)**<-- you are here**
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
