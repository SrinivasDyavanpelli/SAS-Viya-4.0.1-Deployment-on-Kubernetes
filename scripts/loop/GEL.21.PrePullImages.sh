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
        ## docker login cr.sas.com
        ## docker image pull <everything>
        # mkdir -p /tmp/mirror
        # cd /tmp/

        # curl -k https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes/raw/orders/orders/SASdeployment-09QS23-70180938-all-kustomize-2020-03-05T114106.tgz?inline=false \
        #    -o /tmp/mirror/kustomize.tgz
        # curl -k https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes/raw/orders/orders/mirrormgr.docker?inline=false \
        #    -o /tmp/mirror/mirrormgr

        # docker login cr.sas.com -u  -p

        # ./mirrormgr mirror registry -k --destination harbor.$(hostname -f):443 --workers 1 --deployment-data ./order.zip

    ;;

    'start')
        #embed creds into the machine
        # SAS_CR_USERID=
        # SAS_CR_PASSWORD=
        sudo  -u root bash -c ' echo "p-LmLgzRHI1eXe" > /opt/raceutils/.token_user'
        sudo  -u root bash -c '  echo "kfyZONXXVHrsRvx9V6IMLTtPIukGMtMi1ThuuVZ8" > /opt/raceutils/.token_pass'


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

