![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

** THIS IS A DRAFT **

# Using `mirrormgr` to populate the local registry

* [Installing it](#installing-it)
* [pulling down and pushing images into local registry](#pulling-down-and-pushing-images-into-local-registry)
* [Verification](#verification)
* [Navigation](#navigation)

## Installing it

<!--
1. To install it (internal version)

    ```sh
    mirrormgr_URL=https://gelweb.race.sas.com/scripts/PSGEL255/mirrormgr/mirrormgr

    ansible localhost \
        -b --become-user=root \
        -m get_url \
        -a  "url=${mirrormgr_URL} \
            dest=/usr/local/bin/mirrormgr \
            validate_certs=no \
            force=yes \
            owner=root \
            mode=0755 \
            backup=yes" \
        --diff

    ```
 -->

1. Download mirrormgr from the SAS website and install it

    <https://support.sas.com/installation/viya/4/sas-mirror-manager/>

    ```bash

    MIRRORMGR_URL=https://support.sas.com/installation/viya/4/sas-mirror-manager/lax/mirrormgr-linux.tgz

    wget   ${MIRRORMGR_URL} -O - | sudo tar -xz -C /usr/local/bin/
    sudo chmod 0755 /usr/local/bin/

    ```

1. Check version:

    ```bash
    mirrormgr --version

    ```

## pulling down and pushing images into local registry

1. first, we need the certs.zip or the deployment data

    ```bash
    mkdir -p  ~/project/deploy/mirrored
    cd ~/project/deploy/mirrored


    ORDER=9CFHCQ
    ZIP_NAME=$(ls ~/orders/ | grep ${ORDER} | grep "\.zip")

    cp ~/orders/${ZIP_NAME} ~/project/deploy/mirrored

    ls -al ~/project/deploy/mirrored
    ```

1. now run it

    ```bash
    cd  ~/project/deploy/mirrored

    ## display all the available Cadences and Versions for this order
    mirrormgr --deployment-data ${ZIP_NAME} \
        list remote cadences

    ## display all the available Versions and Releases
    mirrormgr --deployment-data ${ZIP_NAME} \
        list remote cadence releases

    mirrormgr --deployment-data ${ZIP_NAME} \
        list remote repos size --latest

    harbor_user=$(cat ~/exportRobot.json | jq -r .name)
    harbor_pass=$(cat ~/exportRobot.json | jq -r .token)

    docker login harbor.$(hostname -f):443 -u ${harbor_user}  -p ${harbor_pass}

    time mirrormgr --deployment-data ~/orders/${ZIP_NAME} mirror registry \
        --destination harbor.$(hostname -f):443/viya \
        --username ${harbor_user} \
        --password ${harbor_pass} \
        --insecure \
        --cadence stable-2020.0.6 \
        --latest \
        --path ~/sas_repo/ \
        --log-file ~/sas_repo/mirrormgr.log \
        --workers 100


    ```

* This will take a long time to run and might have errors in it.
* If so, re-run it a second time.
* If the errors persist, re-run it with `--workers 5` to see if it gets rid of the errors.

Now, check how much space this consumed:

```bash
du --max-depth=1 -h ~/sas_repo/
# 40 GB
sudo du --max-depth=1 -h /srv/nfs/kubedata/harbo*regist*
# 26 GB

```

By mirroring with the `--latest` option, we got the latest images only. However, our Deployment Assets that we will be using soon, they are a bit older than that. So we need to make we sure we also have those older images.

To do so, we now we mirror a specific *release* instead of the latest *release* in the stable-2020.0.6 *version*:

```bash
time mirrormgr --deployment-data ${ZIP_NAME} mirror registry \
    --destination harbor.$(hostname -f):443/viya \
    --username ${harbor_user} \
    --password ${harbor_pass} \
    --insecure \
    --cadence stable-2020.0.6 \
    --release 20201021.1603293493704 \
    --path ~/sas_repo \
    --log-file ~/sas_repo/mirrormgr.log \
    --workers 100
```

Sometimes, the high number of `--workers` is too much for harbor to receive. It's worth re-running it with a more reasonable value.

```bash
time mirrormgr --deployment-data ${ZIP_NAME} mirror registry \
    --destination harbor.$(hostname -f):443/viya \
    --username ${harbor_user} \
    --password ${harbor_pass} \
    --insecure \
    --cadence stable-2020.0.6 \
    --release 20201021.1603293493704 \
    --path ~/sas_repo \
    --log-file ~/sas_repo/mirrormgr.log \
    --workers 4

```


This should run much faster than the previous one.

Now, check how much space is consumed with both the latest images and the older ones:

```bash
du --max-depth=1 -h ~/sas_repo/
#41G
sudo du --max-depth=1 -h /srv/nfs/kubedata/harbo*regist*
#27G
```

## Verification

```sh
ansible all -m shell -a "df -h | grep sda3"
```

At this point, verify that the images are in the registry

```bash
cat ~/urls.md | grep -i harbor

```

may be delete the local copy as this uses up a lot of space:

```sh
# if you run this, it deletes the intermediary copy of the images.
# if you have to mirror again, it will be possible but longer.
rm -rf ~/sas_repo

```

<!--
 testing on azure US and australia

ignore this

```

sudo yum install tmux dstat -y

time mirrormgr --deployment-data SASViyaV4_9CFHCQ_certs.zip mirror registry \
    --destination notused:5001 \
    --latest \
    --path /mnt/resource/sas_repo \
    --log-file ./run1.log

default worker: 16

    display: 321 MiB/s
    dstat: up to 600 M
    it took 9 minutes
    there was 51 GB in the folder


time mirrormgr --deployment-data SASViyaV4_9CFHCQ_certs.zip mirror registry \
    --destination notused:5001 \
    --latest \
    --path /mnt/resource/sas_repo \
    --log-file ./run1.log \
    --workers 32

    display: 500 MiB/s
    dstat: up to 1100 M
    it took 5.5 minutes
    there was 49 GB in the folder


latency: 0.03 s = 30 ms
[cloud-user@mirror-us ~]$ curl ses.sas.download -s -o /dev/null -w  "%{time_starttransfer}\n"
0.234491

wget https://github.com/yuya-takeyama/ntimes/releases/download/v0.1.0/linux_amd64_0.1.0.zip
unzip linux_amd64_0.1.0.zip
wget https://github.com/yuya-takeyama/percentile/releases/download/v0.0.1/linux_amd64_0.0.1.zip
unzip linux_amd64_0.0.1.zip
./ntimes 100 -- curl ses.sas.download -s -o /dev/null -w  "%{time_starttransfer}\n" | ./percentile


[cloud-user@mirror-aus ~]$ mirrormgr --version
mirrormgr:
 version     : 0.25.0
 build date  : 2020-07-26
 git hash    : bcaad82
 go version  : go1.14.2
 go compiler : gc
 platform    : linux/amd64
[cloud-user@mirror-aus ~]$

Australia


sudo mv mirrormgr_1 /usr/local/bin/mirrormgr
sudo chmod 755 /usr/local/bin/mirrormgr
sudo chown cloud-user:cloud-user /usr/local/bin/mirrormgr

sudo mkdir /mnt/resource/sas_repo
sudo chmod 755  /mnt/resource/sas_repo
sudo chown cloud-user:cloud-user  /mnt/resource/sas_repo


time mirrormgr --deployment-data SASViyaV4_9CFHCQ_certs.zip mirror registry \
    --destination notused:5001 \
    --latest \
    --path /mnt/resource/sas_repo \
    --log-file ./run1.log

    display: 65 MiB/s
    dstat: up to 230 M
    it took 20.5 minutes
    there was 51 GB in the folder

rm -rf /mnt/resource/sas_repo/*
time mirrormgr --deployment-data SASViyaV4_9CFHCQ_certs.zip mirror registry \
    --destination notused:5001 \
    --latest \
    --path /mnt/resource/sas_repo \
    --log-file ./run1.log \
    --workers 32


    display: 300 MiB/s
    dstat: up to 230 M
    it took 7 minutes
    there was 51 GB in the folder

slows down at the end.

```
-->

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
* [07 Deployment Customizations / 07 051 Adding a local registry to k8s](/07_Deployment_Customizations/07_051_Adding_a_local_registry_to_k8s.md)
* [07 Deployment Customizations / 07 052 Using mirrormgr to populate the local registry](/07_Deployment_Customizations/07_052_Using_mirrormgr_to_populate_the_local_registry.md)**<-- you are here**
* [07 Deployment Customizations / 07 053 Deploy from local registry](/07_Deployment_Customizations/07_053_Deploy_from_local_registry.md)
* [11 Azure AKS Deployment / 11 011 Creating an AKS Cluster](/11_Azure_AKS_Deployment/11_011_Creating_an_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 012 Performing Prereqs in AKS](/11_Azure_AKS_Deployment/11_012_Performing_Prereqs_in_AKS.md)
* [11 Azure AKS Deployment / 11 013 Deploying Viya 4 on AKS](/11_Azure_AKS_Deployment/11_013_Deploying_Viya_4_on_AKS.md)
* [11 Azure AKS Deployment / 11 014 Deleting the AKS Cluster](/11_Azure_AKS_Deployment/11_014_Deleting_the_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 015 Fast track with cheatcodes](/11_Azure_AKS_Deployment/11_015_Fast_track_with_cheatcodes.md)
* [11 Azure AKS Deployment / 11 131 CAS Customizations](/11_Azure_AKS_Deployment/11_131_CAS_Customizations.md)
* [11 Azure AKS Deployment / 11 132 Install monitoring and logging](/11_Azure_AKS_Deployment/11_132_Install_monitoring_and_logging.md)
<!-- endnav -->
