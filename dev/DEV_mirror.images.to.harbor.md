![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# How to create a new mirror

1. On Openstack machine

1. login as centos

1. choose order and target machine in RACE

    ```sh
    ORDER=09R5VH
    mkdir ~/$ORDER
    cd ~/$ORDER
    echo $ORDER > ./order.txt
    ORDER=$(cat ./order.txt)
    HARBOR_HOST=gelharbor.race.sas.com

    ```

<!--
1. make docker ok with insecure registry:

    ```sh
    ansible localhost -b -m file \
        -a  "path=/etc/docker/daemon.json \
                state=touch"

    ansible sasnode*,localhost -b -m lineinfile \
    -a  "dest=/etc/docker/daemon.json \
        regexp='insecure-registries' \
        line='{ \"insecure-registries\" : [\"$HARBOR_HOST\"] }' \
        state=present \
        backup=yes " \
        --diff

    sudo systemctl restart docker

    ``` -->

1. make a working directory

    ```sh
    mkdir -p ~/$ORDER
    cd ~/$ORDER
    curl -kO http://spsrest.fyi.sas.com:8081/comsat/orders/$ORDER/view/soe/SAS_Viya_deployment_data.zip
    ```

<!--
1. we need to get the certs from the harbor machine:

    ```sh
    sudo mkdir -p /etc/docker/certs.d/$HARBOR_HOST/
    sudo chmod 750 /etc/docker/certs.d/$HARBOR_HOST/

    sudo scp root@$HARBOR_HOST:/registry/certs/domain.crt    /etc/docker/certs.d/$HARBOR_HOST/ca.crt
    ```

1. restart docker:

    ```sh
    sudo systemctl restart docker
    ``` -->

1. Install the latest mirrormgr

    ```bash
    # sadly no worky.
    # had to download to my laptop and upload to jumphost
    #curl -su 'carynt\canepg' https://jenkins3.unx.sas.com/job/dt-mirrormgr_deploy/lastSuccessfulBuild/artifact/build/release/mirrormgr-0.23.4-SNAPSHOT-linux.tgz -o ./mirrormgr.tgz


    tar xvf mirrormgr-0.23.4-SNAPSHOT-linux.tgz

    [centos@canepg-jump 09R4R5]$ ./mirrormgr --version
    mirrormgr:
    version     : 0.23.4-SNAPSHOT
    build date  : 2020-03-30
    git hash    : 1971bad
    go version  : go1.13.8
    go compiler : gc
    platform    : linux/amd64
    ```

1. authenticate to harbor:

    ```sh
    docker login $HARBOR_HOST
    # u: canepg
    # p: "canepg's password for harbor"
    docker image pull centos:7
    docker image tag centos:7 $HARBOR_HOST/library/centos:7
    docker image push $HARBOR_HOST/library/centos:7
    ```

1. clean up old images:

    ```sh
    docker system df
    docker image prune -a
    docker system df

    ```

1. start the mirroring of images:

    ```sh
    cd ~/viya4/$ORDER
    order=$(echo "$ORDER" | awk '{print tolower($0)}')
    echo $order

    ~/$ORDER/mirrormgr  --version

    time ~/$ORDER/mirrormgr mirror registry \
         -k --destination $HARBOR_HOST/${order} \
        --workers 10 \
        --deployment-data ./SAS_Viya_deployment_data.zip \
        --username canepg --password bad_pass_here \
        --path ./my_repo/ --latest

    ```

    cd ~/viya4/$ORDER




    order=$(echo "$(cat order.txt)" | awk '{print tolower($0)}')
    echo $order
    HARBOR_HOST=gelharbor.race.sas.com


    time ./mirrormgr mirror registry \
         -k --destination $HARBOR_HOST/${order} \
        --workers 1 \
        --deployment-data ./SAS_Viya_deployment_data.zip \
        --path ./my_repo/ --latest \
        --username canepg --password _this_is_not_the_pass_



