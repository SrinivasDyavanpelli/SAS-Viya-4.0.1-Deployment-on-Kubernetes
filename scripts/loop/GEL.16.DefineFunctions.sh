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

    ;;
    'dev')

    ;;

    'start')

        if  [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ;     then

        ansible 'localhost' -m 'blockinfile' \
          -a 'path=/home/cloud-user/.bashrc \
              backup=no \
              block="
# Define functions
gel_setCurrentNamespace () { ~/PSGEL260-sas-viya-4.0.1-administration/scripts/gel_tools/gel_setupDefaultNamespaceInBashrc.sh "$@"; source ~/.bash_profile; }
. ~/PSGEL260-sas-viya-4.0.1-administration/scripts/gel_tools/gel_defineAdminContainerFunctions.sh
" \
              state=present \
              marker=""' \
          --diff

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
