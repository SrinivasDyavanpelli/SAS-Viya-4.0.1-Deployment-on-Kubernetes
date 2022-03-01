![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploy OpenLDAP and PHPLDAPAdmin on Kubernetes - A case study

* [Introduction](#introduction)
* [Skipping and re-doing](#skipping-and-re-doing)
* [List of users in the target LDAP](#list-of-users-in-the-target-ldap)
* [Preparation](#preparation)
* [Namespace](#namespace)
  * [Imperative creation of a namespace](#imperative-creation-of-a-namespace)
  * [Declarative creation of a namespace](#declarative-creation-of-a-namespace)
  * [Confirm namespace existence and set it as default](#confirm-namespace-existence-and-set-it-as-default)
* [Creating a configmap for the OpenLDAP Server](#creating-a-configmap-for-the-openldap-server)
* [Creating a Deployment definition for the OpenLDAP Server](#creating-a-deployment-definition-for-the-openldap-server)
* [OpenLDAP Service](#openldap-service)
* [PHPLDAPAdmin  Deployment](#phpldapadmin-deployment)
* [PHPLDAPAdmin  Service](#phpldapadmin-service)
* [PHPLDAPAdmin  Ingress](#phpldapadmin-ingress)
* [URLs](#urls)
* [Managing](#managing)
* [Changing which namespace is the default one](#changing-which-namespace-is-the-default-one)
* [Manual Scaling](#manual-scaling)
* [stickiness](#stickiness)
* [Unset the default namespace](#unset-the-default-namespace)
* [Reset](#reset)

## Introduction

* Viya 4.0 is a  complex application.
* Getting exposed to Kubernetes through an application as complex as Viya 4 is not the best way to come to grips with Kubernetes
* So, as an on-ramp to the concepts of Containers, and of Kubernetes, we will be first creating a much simpler application: an LDAP server
* This choice is not random: In order to be able to Log into Viya 4, this Viya needs to be connected to the customer's corporate LDAP
* In our case, we will build our own LDAP, and then connect Viya 4 to it
* As a final warning, the steps are very progressive: going over multiple iterations is there to show you the ropes. If you are in a rush, you'd just skip to the end.

<!--
    ```bash

    undo_it () {

    if kubectl get ns | grep -q 'ldap-basic\ '
    then
        kubectl -n ldap-basic delete deployments --all
        kubectl -n ldap-basic delete services --all
        kubectl -n ldap-basic delete pods --all --force --grace-period=0
        kubectl -n ldap-basic delete ing --all
        kubectl delete ns ldap-basic
        rm -rf ~/project/ldap/basic

    fi

    }

    undo_it

    if  [ "$1" == "reset" ]; then
        exit
    fi

    ```
 -->

## Skipping and re-doing

This hands-on will walk you through the steps to setup OpenLDAP and PHP-LDAP-Admin.

I suggest you first do it in "accelerated mode", aka, CheatCodes.

To do so, simply execute the following command:

```sh
bash ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/02_Kubernetes_and_Containers_Fundamentals/01_Deploy_OpenLDAP_and_PHPLDAPAdmin_on_Kubernetes.sh
```

When it's finished running, skip to the [Managing](#managing) section

## List of users in the target LDAP

I'm going to maintain here a list of the accounts/passwords that will exist in the LDAP once it's deployed.

<!--
| `admin`          | `lnxsas`                       |
-->

| user             | password                       |
|------------------|--------------------------------|
| `sasdemo`        | `lnxsas`                       |
| `sasadm`         | `lnxsas`                       |
| `sastest1`       | `lnxsas`                       |
| `sastest2`       | `lnxsas`                       |

## Preparation

1. Creating folders:

    ```bash
    rm -rf ~/project/ldap/basic
    mkdir -p ~/project/ldap/basic

    ```

1. Copying the LDAP Manifest files into the project folder

    ```bash
    cp -rp ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/02_Kubernetes_and_Containers_Fundamentals/ldap-basic/* ~/project/ldap/basic/
    ```

1. Committing the LDAP changes in Version control

    ```bash
    cd ~/project/ldap/basic

    # DO: use your first and last name
    # DO: put a dash (-) between them
    # DO NOT: use an underscore
    # DO NOT: use your SAS ID (I don't know who sasabc is. )
    # DO NOT: use Erwan's name. Get your own name.
    my_name=erwan-granger

    git init
    git config --local user.email "$my_name@ItDoesNotMatter.com"
    git config --local user.name "$my_name"

    git add *
    git commit -m "Adding the files for basic LDAP"

    ```

## Namespace

I like to keep things separate whenever I can. So we will want our OpenLDAP to have its own Namespace.

There are multiple ways of creating a namespace:

* IMPERATIVE: You could  use an ad-hoc kubectl command to ask for the namespace to be created.
* DECLARATIVE: You could create a YAML file describing what the namespace should be like and then ask kubernetes to make it happen.

I'll show both ways below. Choose one or the other. If you do both, you will get some slightly different messages.

### Imperative creation of a namespace

1. We could do an ad-hoc command like such:

    ```sh
    kubectl create ns ldap-basic
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    namespace/ldap-basic created
    ```

    </details>

### Declarative creation of a namespace

1. Or we could use a more declarative way, and use .yaml file with the namespace definition in it:

    ```sh
    pygmentize ~/project/ldap/basic/01-ldap-basic-namespace.yaml

    ```

1. And to apply that definition:

    ```bash
    kubectl apply -f ~/project/ldap/basic/01-ldap-basic-namespace.yaml

    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    namespace/ldap-basic created
    ```

    </details>

### Confirm namespace existence and set it as default

1. We now have a new namespace called open-ldap, as confirmed by the `kubectl get ns` command:

    ```log
    [cloud-user@rext03-0052 ~]$ kubectl get ns
    NAME              STATUS   AGE
    kube-system       Active   21h
    default           Active   21h
    kube-public       Active   21h
    kube-node-lease   Active   21h
    ldap-basic        Active   78s
    [cloud-user@rext03-0052 ~]$
    ```

1. Temporarily set the default namespace to be open-ldap, so we do not have to keep specifying it:

    ```bash
    ## See default value in the current context before we change it
    kubectl config get-contexts
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    [cloud-user@rext03-0194 basic]$ kubectl config get-contexts
    CURRENT   NAME         CLUSTER      AUTHINFO                NAMESPACE
    *         gelcluster   gelcluster   kube-admin-gelcluster   functional
    [cloud-user@rext03-0194 basic]$
    ```

    </details>

1. Now we set it to **ldap-basic**

    ```bash
    ## Temporarily set the default namespace
    kubectl config set-context --current --namespace=ldap-basic
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    [cloud-user@rext03-0194 basic]$     kubectl config set-context --current --namespace=ldap-basic
    Context "gelcluster" modified.
    [cloud-user@rext03-0194 basic]$
    ```

    </details>

1. Now re-run `kubectl config get-contexts` to confim the default namespace has changed.

## Creating a configmap for the OpenLDAP Server

1. The config-map file contains the content of an LDIF file that helps us seed LDAP with default accounts

    ```bash
    ## create
    kubectl apply -f  ~/project/ldap/basic/02-openldap-configmap.yaml

    ## confirm
    kubectl describe configmap openldap-bootstrap

    ```

## Creating a Deployment definition for the OpenLDAP Server

1. create a deployment file:

    ```bash
    pygmentize ~/project/ldap/basic/03-openldap-deployment.yaml
    kubectl apply -f ~/project/ldap/basic/03-openldap-deployment.yaml
    kubectl get pods -o wide

    ## this command will wait for the pod to be running
    while [[ $(kubectl get pods -l app=openldap-server -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done

    podname=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')
    kubectl describe pod $podname
    kubectl logs $podname

    ```

## OpenLDAP Service

1. and now a service:

    ```bash
    pygmentize ~/project/ldap/basic/04-openldap-service.yaml
    kubectl apply -f ~/project/ldap/basic/04-openldap-service.yaml
    kubectl get services -o wide

    ```

## PHPLDAPAdmin  Deployment

1. and now PHPLDAP Admin

    ```bash
    pygmentize ~/project/ldap/basic/05-php-ldap-admin-deployment.yaml
    kubectl apply -f ~/project/ldap/basic/05-php-ldap-admin-deployment.yaml

    while [[ $(kubectl get pods -l app=php-ldap-admin -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done

    kubectl get pods -o wide

    podname=$(kubectl get pods --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep php | head -n 1)

    kubectl logs $podname

    ```

## PHPLDAPAdmin  Service

1. and the service for it:

    ```bash
    pygmentize ~/project/ldap/basic/06-php-ldap-admin-service.yaml
    kubectl apply -f ~/project/ldap/basic/06-php-ldap-admin-service.yaml

    ```

## PHPLDAPAdmin  Ingress

1. Choosing an ingress for phpldapadmin

    ```bash
    INGRESS_ALIAS="phpldapadmin.$(hostname -f)"

    ansible localhost \
    -m lineinfile \
    -a  "dest=~/project/ldap/basic/07-php-ldap-admin-ingress.yaml \
        regexp='^    - host:' \
        line='    - host: ${INGRESS_ALIAS}' \
        state=present \
        backup=yes " \
        --diff
    ```

1. let's commit that to Version control:

    ```bash
    cd ~/project/ldap/basic
    git add *
    git commit -m "Changing the Ingress Name to match your environment"
    ```

1. Display and apply the ingress:

    ```bash
    pygmentize ~/project/ldap/basic/07-php-ldap-admin-ingress.yaml
    kubectl apply -f ~/project/ldap/basic/07-php-ldap-admin-ingress.yaml
    kubectl get ing
    ```

1. display some things

    ```bash
    kubectl get all,ing
    kubectl get pods -o wide
    ```

## URLs

1. Run the following code

    ```bash
    printf "\n* [PHP LDAP Admin (basic) URL (HTTP )](http://phpldapadmin.$(hostname -f)/ ) \n\n" | tee -a ~/urls.md
    printf "\n* [PHP LDAP Admin (basic) URL (HTTP**S**)](https://phpldapadmin.$(hostname -f)/ ) \n\n" | tee -a ~/urls.md
    ```

1. If you Ctrl-Click on the Hostnames, it will open them up in your browser.

## Managing

Here I will show you how to manage your application

## Changing which namespace is the default one

The default Namespace is called "default". The following command will change that and make **ldap-basic** the new default:

1. Set  **ldap-basic** as the default namespace

    ```bash
    ## Temporarily set the default namespace
    kubectl config set-context --current --namespace=ldap-basic
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    [cloud-user@rext03-0194 basic]$     kubectl config set-context --current --namespace=ldap-basic
    Context "gelcluster" modified.
    [cloud-user@rext03-0194 basic]$
    ```

    </details>

1. Now re-run `kubectl config get-contexts` to confim the default namespace has changed.

## Manual Scaling

1. Display the name of the pods and of the deployments, in the ldap-basic namespace (remember that we set ldap-basic as the default namespace earlier):

    ```bash
    kubectl get pods,deployments
    ```

1. You can see that the deployment name is "static" enough, but the pod names have some randomness to them at the end:

    ```log
    NAME                                  READY   STATUS    RESTARTS   AGE
    pod/openldap-server-bc7c664d8-qntcc   1/1     Running   0          19s
    pod/php-ldap-admin-76b47b7c47-bb4hx   1/1     Running   0          16s

    NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/openldap-server   1/1     1            1           19s
    deployment.apps/php-ldap-admin    1/1     1            1           16s
    ```

1. Let's ask kubernetes to resize our php-ldap-admin deployment:

    ```bash
    kubectl scale deployment php-ldap-admin --replicas=4
    ```

1. if you then re-run the "get pods,deployments" command, you will see:

    ```log
    [cloud-user@pdcesx04222 basic]$     kubectl get pods,deployments
    NAME                                  READY   STATUS              RESTARTS   AGE
    pod/openldap-server-bc7c664d8-qntcc   1/1     Running             0          2m52s
    pod/php-ldap-admin-76b47b7c47-bb4hx   1/1     Running             0          2m49s
    pod/php-ldap-admin-76b47b7c47-fr86m   0/1     ContainerCreating   0          2s
    pod/php-ldap-admin-76b47b7c47-mhl78   0/1     ContainerCreating   0          2s
    pod/php-ldap-admin-76b47b7c47-phjbz   0/1     ContainerCreating   0          2s

    NAME                              READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/openldap-server   1/1     1            1           2m52s
    deployment.apps/php-ldap-admin    1/4     4            1           2m49s
    ```

1. Another, more permanent way of scaling is to edit the original .yaml files and to re-apply them:

1. Would you know how to do that without help?

1. if not, unfold below:

    <details><summary>Click here to see the steps</summary>

    ```bash
    cd ~/project/ldap/basic/

    ansible localhost \
    -m lineinfile \
    -a  "dest=~/project/ldap/basic/05-php-ldap-admin-deployment.yaml \
        regexp='^  replicas:' \
        line='  replicas: 2' \
        state=present \
        backup=yes " \
        --diff


    git add 05-php-ldap-admin-deployment.yaml
    git commit -m "permanently changing the replicas of PHP-LDAP-Admin to 2"

    kubectl apply  -f ~/project/ldap/basic/05-php-ldap-admin-deployment.yaml

    ```

    </details>

## stickiness

The ingress and service definitions for php-ldap-admin contain that make things "sticky".

If you are balanced to one pod of php-ldap-admin, you will stay connected to that pod.

This is because php-ldap-admin is not fully stateless.

It seems to work, so I'll leave that as-is.

## Unset the default namespace

1. It is no longer helpful to have the default namespace be ldap-basic after this exercise, so unset it.

    ```bash
    ## See default value in the current context before we change it
    kubectl config get-contexts
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    [cloud-user@rext03-0052 ~]$ kubectl config get-contexts
    CURRENT   NAME      CLUSTER   AUTHINFO   NAMESPACE
    *         default   default   default    ldap-basic
    [cloud-user@rext03-0052 ~]$
    ```

    </details>

1. Now we reset the default namespace to default

    ```bash
    ## Unset the default namespace
    kubectl config set-context --current --namespace=default
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    [cloud-user@rext03-0052 ~]$ kubectl config get-contexts
    CURRENT   NAME      CLUSTER   AUTHINFO   NAMESPACE
    *         default   default   default
    [cloud-user@rext03-0052 ~]$
    ```

    </details>

## Reset

If you want to go through this again, more slowly, you can run the following command to **reset** the environment to the beginning of the exercise

```sh
bash ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/02_Kubernetes_and_Containers_Fundamentals/01_Deploy_OpenLDAP_and_PHPLDAPAdmin_on_Kubernetes.sh reset
```

