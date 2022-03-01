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

        sudo rm -f /usr/local/bin/kustomize

    ;;
    'dev')

    ;;

    'start')

        if  [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ;     then

        ## KUSTOMIZE
        logit "installing Kustomize"
        sudo rm -f /home/cloud-user/kustomize
        sudo rm -f /tmp/kustomize.tgz
        sudo rm -f /usr/local/bin/kustomize
        sudo rm -f /usr/local/bin/yq

        sudo -u cloud-user bash -c "cd /tmp ; ansible localhost \
            -b --become-user=root \
            -m get_url -a  \
                \"url=https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv3.7.0/kustomize_v3.7.0_linux_amd64.tar.gz \
                dest=/tmp/kustomize.tgz \
                validate_certs=no \
                force=yes \
                owner=root \
                mode=0755 \
                backup=yes\" \
                --diff"

        sudo -u cloud-user bash -c "cd /tmp/ ; tar xf /tmp/kustomize.tgz "

        sudo -u root bash -c "cp /tmp/kustomize /usr/local/bin/kustomize; \
                                chmod 755 /usr/local/bin/kustomize ; \
                                chown root:root /usr/local/bin/kustomize "

        # issue with the latest version of kustomize (3.5.5)
        # curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash && sudo mv kustomize /usr/local/bin
        logit "Installed Kustomize version $(kustomize version --short)"

        # Install yq, in case we need it.
        sudo -u cloud-user bash -c " cd /tmp ;  ansible localhost \
            -b --become-user=root \
            -m get_url -a  \
                \"url=https://github.com/mikefarah/yq/releases/download/3.2.1/yq_linux_amd64 \
                dest=/usr/local/bin/yq \
                validate_certs=no \
                force=yes \
                owner=root \
                mode=0755 \
                backup=yes\" \
                --diff"

        fi
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

