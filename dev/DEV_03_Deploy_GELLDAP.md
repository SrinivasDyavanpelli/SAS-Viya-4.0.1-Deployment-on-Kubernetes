![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploy the Portable OpenLDAP in Kubernetes

* [Introduction](#introduction)
* [Skipping and re-doing](#skipping-and-re-doing)
* [Preparation](#preparation)
* [Namespace choice](#namespace-choice)
* [Deploy the GEL Portable OpenLDAP](#deploy-the-gel-portable-openldap)

## Introduction

The instructions in this document will walk you through setting up a basic OpenLDAP.

To avoid confusion, I'll refer to it as the "GEL Portable LDAP".

The relevant files are located in [this folder](/02_Kubernetes_and_Containers_Fundamentals/gel-portable-ldap/)

## Skipping and re-doing

I suggest you first do it in "accelerated mode", aka, CheatCodes.

To do so, simply execute the following command:

```sh
bash ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/02_Kubernetes_and_Containers_Fundamentals/03_Deploy_GELLDAP.sh gelldap
```

## Preparation

1. Creating folders:

    ```bash
    rm -rf ~/project/gelldap/
    mkdir -p ~/project/gelldap/

    ```

1. Cloning the project:

    ```bash
    cd ~/project/
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/project/gelldap/
    git fetch --all
    git reset --hard origin/master
    ```

## Namespace choice

We need to decide which namespace we will put this OpenLDAP into.

Putting it in the same Namespace as Viya is going to be my recommended practice.

1. Choose the namespace

    ```sh
    # Let's save the namespace as an Environment variable:
    NS=gelldap

    echo ${NS}

    ```

1. Create the namespace

    ```sh
    kubectl create ns ${NS}

    ```

<!--
    ```bash
    if  [ "$1" == "" ]; then
        NS=gelldap
        kubectl delete ns ${NS}
        kubectl create ns ${NS}
    else
        NS=$1
    fi

    ```
 -->

## Deploy the GEL Portable OpenLDAP

1. Apply the manifest, against the namespace:

    ```bash

    cd ~/project/gelldap/
    kustomize build ./no_TLS/ | kubectl -n ${NS} apply -f -

    cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
       ~/project/deploy/${NS}/site-config/


    ```

1. Wait for pod to be running

    ```bash
    app=gelldap-server
    while [[ $(kubectl -n ${NS} get pods -l app=${app} -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod ${app}" && sleep 1; done

    ```

1. Confirm that things look OK:

    ```bash
    kubectl -n ${NS} get all -o wide

    ```

1. You should see:

    ```log
    NAME                                            READY   STATUS    RESTARTS   AGE   IP            NODE        NOMINATED NODE   READINESS GATES
    pod/gelldap-server-77c6f9dd84-9mqz7   1/1     Running   0          25s   10.42.1.113   intnode03   <none>           <none>

    NAME                                TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE   SELECTOR
    service/gelldap-service   ClusterIP   10.43.86.12   <none>        389/TCP   25s   app=gelldap-server

    NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS                 IMAGES                   SELECTOR
    deployment.apps/gelldap-server   1/1     1            1           25s   gelldap-server   osixia/openldap:stable   app=gelldap-server

    NAME                                                  DESIRED   CURRENT   READY   AGE   CONTAINERS                 IMAGES                   SELECTOR
    replicaset.apps/gelldap-server-77c6f9dd84   1         1         1       25s   gelldap-server   osixia/openldap:stable   app=gelldap-server,pod-template-hash=77c6f9dd84

    ```
