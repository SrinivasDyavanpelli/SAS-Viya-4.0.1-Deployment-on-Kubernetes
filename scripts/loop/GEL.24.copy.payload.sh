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

function copy_payload () {

    GELWEB_PAYLOAD_URL=https://gelweb.race.sas.com/scripts/PSGEL255/payload/payload.tgz
    # ORDERS=$(curl -s  ${GELWEB_ORDERS_FOL} | grep -o 'href=".*\.tgz"'  \
    #     | sed 's|href=||g' | sed 's|"||g')
    # echo "display available orders"
    # printf "$ORDERS"

    rm -rf ~/payload/

    curl -o ~/payload.tgz ${GELWEB_PAYLOAD_URL}

    cd ~/

    tar xf  ~/payload.tgz

}


case "$1" in
    'enable')

    ;;
    'dev')

    ;;

    'start')
        if [ "$race_alias" == "sasnode01" ]  ;     then

            FCO=$(declare -f copy_payload)
            sudo  -u cloud-user bash -c "$FCO; copy_payload"

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
