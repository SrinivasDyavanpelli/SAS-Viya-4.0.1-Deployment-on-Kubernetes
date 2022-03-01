#!/bin/bash

echo "creating the cheatcodes , if on buildbox"

timestamp() {
  date +"%T"
}
datestamp() {
  date +"%D"
}

## Read in the id file. only really needed if running these scripts in standalone mode.
source <( cat /opt/raceutils/.bootstrap.txt  )
source <( cat /opt/raceutils/.id.txt  )
reboot_count=$(cat /opt/raceutils/.reboot.txt)

case "$1" in
    'enable')

    ;;
    'start')

        if [ "$race_alias" = "sasnode01" ] ; then

            # store the order number in the home dir:
            # ORDERNUM
            ORDERNUM=09QTRD
            # rel-ver 2020.03.18
            ORDERNUM=09QX3B
            # rel-ver 2020.03.18
            ORDERNUM=09QWS3
            # rel-ver 2020.03.19
            ORDERNUM=09QXCR
            # rel-ver 2020.04.07
            ORDERNUM=09R5VH
            sudo -u cloud-user bash -c "echo ${ORDERNUM} > ~/order.txt"

            STABLE_ORDERNUM=09RZ8L
            sudo -u cloud-user bash -c "echo ${STABLE_ORDERNUM} > ~/stable_order.txt"

            echo "$(datestamp) $(timestamp): Creating cheatcodes " >> ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
            sudo -u cloud-user bash -c "$RACEUTILS_PATH/cheatcodes/create.cheatcodes.sh ~/$GIT_REPO_NAME/ "

            sudo -u cloud-user bash -c "cd ~/$GIT_REPO_NAME/ ; \
                cat _all.sh | grep -E '06_Deploy' | grep -E '011|012|013' > ./_lab_dev.sh "
            sudo -u cloud-user bash -c "cd ~/$GIT_REPO_NAME/ ; \
                cat _all.sh | grep -E '06_Deploy' | grep -E '011|012' > ./_autodeploy-lab_.sh "
            sudo -u cloud-user bash -c "cd ~/$GIT_REPO_NAME/ ; \
                cat _all.sh | grep -E '01_000'  > ./_autodeploy-gelenv_.sh "
            # sudo -u cloud-user bash -c "cd ~/PSGEL225-deploying-viya-3.5-on-containers ; cat _all.sh | grep -E '11|12|13|14' | grep -v -E 'POSI|POMI|SetupGrafana' > _fumi_all.sh "
        fi

    ;;
    'stop')

    ;;
    'clean')

    ;;

    *)
        printf "Usage: GEL.04.Create.Cheatcodes.sh {enable/start|stop|clean} \n"
        exit 1
    ;;
esac
