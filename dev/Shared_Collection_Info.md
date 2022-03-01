![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Shared Collection Information

## About

* There are some long-running, shared environments in RACE.
* This document explains their use

## Advantages

* You don't have to book anything
* You can access them on short notice, 24/7
* Things are already done for you

## Inconvenients

* You have to play nice with others
* You won't be able to do everything that you could if you accessed a private environment
* These environments will go stale after a while
* You can't use the environment's Windows machine
* Things are already done for you

## Environment Details

| Name               | Hostname                       |
|--------------------|--------------------------------|
| GEL Prod-5 Stable  | `gelprod5stable.race.sas.com`  |

## How to use this environment

### Get connected

1. Connect to the environment's sasnode01 (choose from above):
   * Connection type: SSH
   * u: `cloud-user`
   * p: `lnxsas`

### Prepare your playpen

1. Put your name in an environment variable (change it to use your own name):

    ```sh
    # DO: use your first and last name
    # DO: put a dash (-) between them
    # DO NOT: use an underscore
    # DO NOT: use your SAS ID (I don't know who sasabc is. )
    my_name=erwan-granger

    ```

1. Delete your named project folder if it was already created at least once in shared environment :

    ```sh
    rm -rf ~/project/deploy/$my_name/
    ```

1. Create your named project folder :

    ```sh
    mkdir -p ~/project/deploy/$my_name
    cd ~/project/deploy/$my_name/

    ```

1. Copy the default "functional" environment into your private folder

    ```sh
    cp -rp  ~/project/deploy/functional/* ~/project/deploy/$my_name/
    ```

1. Initialize your own Git repo

    ```sh
    cd ~/project/deploy/$my_name/
    git init
    git config --local user.email "$my_name@ItDoesNotMatter.com"
    git config --local user.name "$my_name"
    git add *
    git commit -m "Starting Version Control on my private project"
    ```

1. Create your namespace:

    ```sh
    kubectl create ns $my_name

    ```

1. See how many people have created a namespace so far

    ```sh
    kubectl get ns

    ```

### Create your private deployment

1. Update your kustomization file so that the namespace and ingress match your name:

    ```sh
    cd ~/project/deploy/$my_name/
    ansible localhost -m replace -a "path=./kustomization.yaml regexp='functional' replace='$my_name'" --diff

    ```

1. Re-generate the site.yaml file:

    ```sh
    cd ~/project/deploy/$my_name/
    kustomize build > site.yaml

    ```

1. Commit your changes to version control:

    ```sh
    cd ~/project/deploy/$my_name/
    git add *
    git commit -m "Updated namespace and URL in the kustomization file and re-generated site.yaml"

    ```

### Start your private deployment

1. Now is the time to apply your custom site.yaml

    ```sh
    cd ~/project/deploy/$my_name/
    kubectl apply -f site.yaml -n $my_name

    ```

1. And now we wait for the deployment to be ready:

    ```sh
    time  gel_OKViya4 -n $my_name --wait

    ```

1. At first, you will see that the endpoints are not ready:

    <details><summary>Click here to see the expected output</summary>

    ```log
    OK     20200324-105947 We have checked 101 endpoints. We found 0 working, and 101 failing
    FAIL   20200324-105947 Success Rate (0 %) is not high enough:
    FAIL   20200324-105947 Trying again in 10 seconds.
    ```

    </details>

1. After about 10 minutes, it should stop scrolling and inform you that  things are mostly ready:

    <details><summary>Click here to see the expected output</summary>

    ```log
    OK     20200324-110444 We have checked 101 endpoints. We found 99 working, and 2 failing
    OK     20200324-110444 Success Rate (98 %) is as good as it will get
    ```

    </details>

1. If the environment is too full, check if your pods are in a **Pending** state.

    ```sh
    kubectl get po -n $my_name

    ```
    If they are, you'll need to ask the others to make some room for you.

1. Figure out whose pods are hogging the system:

    ```sh
    kubectl top pods  -A

    ```

1. Ask the person(s) with running environment if it's ok to scale down their pods. If they don't respond, do it for them.

### Scale down and clean

1. First, to scale down the pods , you can execute this:

    ```sh
    kubectl scale deployment,statefulset --all --replicas=0 -n $my_name

    ```

1. However, we need to go a bit further to really make room for others, so please also delete the inside of your namespace:

    ```sh
    kubectl delete all,ing,pvc --all -n $my_name

    ```

1. If you really want to be thorough, you can also simply delete your namespace itself:

    ```sh
    kubectl delete ns $my_name
    ```


## Back to the main README

Go back to the [main readme](/README.md)