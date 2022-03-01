#!/bin/bash

timestamp() {
  date +"%T"
}
datestamp() {
  date +"%D"
}

function logit () {
    sudo touch ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
    sudo chmod 777 ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
    printf "$(datestamp) $(timestamp): $1 \n"  | tee -a ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
}

## Read in the id file. only really needed if running these scripts in standalone mode.
source <( cat /opt/raceutils/.bootstrap.txt  )
source <( cat /opt/raceutils/.id.txt  )
reboot_count=$(cat /opt/raceutils/.reboot.txt)

case "$1" in
    'enable')

        if  [ "$race_alias" == "sasnode01" ] ; then

            sudo -u cloud-user bash -c "ansible sasnode* -m shell -b -a ' docker rm -f \$(docker ps -qa) ; \
            docker volume rm -f \$(docker volume ls -q) ; \
            cleanupdirs=\"/var/lib/etcd /etc/kubernetes /etc/cni /opt/cni /var/lib/cni /var/run/calico /opt/rke\" ; \
            for dir in \$cleanupdirs; do  \
            rm -rf \$dir ;\
            done '"
            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'docker image prune -a --force ' "

            sudo yum-complete-transaction -y

            sudo yum remove docker-ce docker-ce-cli -y
        fi

    ;;
    'start')


        if  [ "$collection_size" -gt "2"  ] && [ "$reboot_count" -le "1" ] ; then
            logit "We are running on a multi-machine collection with $collection_size servers"


            logit "Installing Docker, on all machines in the collection "
            # bash -x /opt/raceutils/scripts/setup.docker.sh
            #sudo -u cloud-user bash -c "ansible  sasnode*  -b -m shell -a 'curl https://releases.rancher.com/install-docker/18.09.2.sh | sh' "
            sudo -u cloud-user bash -c "ansible  sasnode*  -b -m shell -a 'curl https://releases.rancher.com/install-docker/19.03.5.sh | sh' "
            sudo -u cloud-user bash -c "ansible  sasnode*  -m shell -a 'docker --version' "
            sudo -u cloud-user bash -c "ansible  sasnode*  -b -m shell -a 'usermod -aG docker cloud-user' "
            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'systemctl restart docker' "

        fi

        if  [ "$collection_size" = "2"  ] && [ "$reboot_count" -le "1" ] ; then
            logit "We are running on a single machine"

            logit "Installing Docker "
            bash -x /opt/raceutils/scripts/setup.docker.sh

        fi

        ## we really need the latest version of containerd.
        ## but we have to wait until after the install to update it
        sudo -u cloud-user bash -c "ansible  sasnode*  -b -m yum  -a 'name=containerd state=latest ' "
        sudo -u cloud-user bash -c "ansible  sasnode*  -b -m yum  -a 'name=containerd.io state=latest ' "
        sudo -u cloud-user bash -c "ansible  sasnode* -b  -m service -a 'name=containerd state=restarted enabled=yes' "


        # enable docker debugging

## create template:
sudo bash -c "cat << EOF > /tmp/daemon.json.j2
{
    \"debug\": true,
    \"shutdown-timeout\": 120,
    \"live-restore\": true,
    \"insecure-registries\": [\"harbor.$(hostname -f):443\"]
}
EOF"


        sudo -u cloud-user bash -c "ansible  sasnode*  -b -m template -a 'src=/tmp/daemon.json.j2 dest=/etc/docker/daemon.json owner=root group=root mode=0640' "
        sudo -u cloud-user bash -c "ansible  sasnode*  -b -m shell -a 'cat /etc/docker/daemon.json' "

        # sudo -u cloud-user bash -c "ansible  sasnode*  -b -m shell -a ' kill -SIGHUP \$(pidof dockerd)' "
        sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'systemctl reset-failed docker.service' "
        sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'systemctl restart docker' "
        ansible  sasnode* -b  -m service -a 'name=docker state=restarted enabled=yes'


        # sudo -u cloud-user bash -c "ansible  sasnode*  -b -m file -a 'path=/etc/docker/daemon.json owner=root group=root state=touch mode=0640' "
        # sudo -u cloud-user bash -c "ansible  sasnode*  -b -m shell -a 'printf \"{\n\\\"debug\\\": true\n}\" > /etc/docker/daemon.json' "
        #sudo -u cloud-user bash -c "ansible  sasnode*  -b -m shell -a 'printf \"{\n\\\"debug\\\": true,\n\\\"shutdown-timeout\\\": 60\n}\" > /etc/docker/daemon.json' "
        # sudo -u cloud-user bash -c "ansible  sasnode*  -b -m shell -a 'printf \"{\n\\\"debug\\\": true,\n\\\"shutdown-timeout\\\": 120\n}\" > /etc/docker/daemon.json' "
        # sudo -u cloud-user bash -c "ansible  sasnode*  -b -m shell -a 'printf \"{\n\\\"debug\\\": true,\n\\\"shutdown-timeout\\\": 120,\n\\\"live-restore\\\": true\n}\" > /etc/docker/daemon.json' "

        #sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'journalctl -u docker.service --no-pager  --since today' "
        #sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'journalctl -u docker.service --no-pager  --since today' "

        # journalctl --flush
        # journalctl --vacuum-time=1s
        # journalctl --vacuum-size=1M
        # journalctl --disk-usage
        # journalctl -u docker.service --no-pager  --since today


    ;;
    'stop')

    ;;
    'clean')

    ;;

    *)
        printf "Usage: GEL.00.Clone.Project.sh {enable/start|stop|clean} \n"
        exit 1
    ;;
esac

