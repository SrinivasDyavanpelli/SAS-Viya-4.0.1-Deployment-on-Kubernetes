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
        sudo rm -f /usr/local/bin/helm

    ;;
    'dev')

    ;;

    'start')

        if  [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ;     then
        ## HELM
        # curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
        # chmod 700 /tmp/get_helm.sh
        # /tmp/get_helm.sh
        # logit "Installed Helm version $(helm version --short)"
        # rm -rf /tmp/get_helm.sh

        sudo -u root bash -c "rm -rf /tmp/linux-amd64 /tmp/helm.tar.gz /usr/local/bin/helm"

        ansible localhost \
            -b --become-user=root \
            -m get_url -a  \
                "url=https://get.helm.sh/helm-v3.2.1-linux-amd64.tar.gz \
                dest=/tmp/helm.tar.gz \
                validate_certs=no \
                force=yes \
                owner=root \
                mode=0755 \
                backup=yes" \
                --diff

        sudo -u cloud-user bash -c "cd /tmp/ ; tar xf /tmp/helm.tar.gz "

        sudo -u root bash -c "cp /tmp/linux-amd64/helm /usr/local/bin/helm; \
                                chmod 755 /usr/local/bin/helm ; \
                                chown root:root /usr/local/bin/helm "

        sudo -u root bash -c "rm -rf /tmp/linux-amd64 /tmp/helm.tar.gz"

        logit "Installed Helm version $(helm version --short) \n"

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

