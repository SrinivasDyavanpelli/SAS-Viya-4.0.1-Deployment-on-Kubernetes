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
logit "Reboot Count is $reboot_count "
if [ "$reboot_count" -le "1" ] ; then
    logit "because reboot count is $reboot_count, all the start sections will fire"
fi
if [ "$reboot_count" -gt "1" ] ; then
    logit "because reboot count is $reboot_count , we won't re-do quite everything"
fi

case "$1" in
    'enable')
        printf "Cloning project the cloned project\n"

        echo "$race_alias"

        sudo -u cloud-user bash -c "rm -rf ~/PSGEL225-deploying-viya-3.5-on-containers"
        sudo -u cloud-user bash -c "rm -rf ~/smpk8s-testing"
        sudo -u cloud-user bash -c "rm -rf ~/urls.md"

        if  [ "$race_alias" == "sasnode01" ] ;     then
            echo "$(datestamp) $(timestamp): Initializing git project clone " >> ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
            sudo -u cloud-user bash -c "ls -l ~"
            sudo -u cloud-user bash -c "rm -rf ~/$GIT_REPO_NAME/ "
            sudo -u cloud-user bash -c "cd ~ ; git clone --branch $BRANCH $GIT_CLONE_URL "
        fi

    ;;
    'start')
        printf "Updating the cloned project\n"

        echo "$race_alias"

        if  [ "$race_alias" == "sasnode01" ] ;     then
            echo "$(datestamp) $(timestamp): Refreshing project clone " >> ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
            sudo -u cloud-user bash -c "ls -al ~"
            # sudo -u cloud-user bash -c "cd ~ ; git clone --branch $BRANCH $GIT_CLONE_URL || (cd ~/$GIT_REPO_NAME ; git pull)"
            sudo -u cloud-user bash -c "cd ~ ; git clone --branch $BRANCH $GIT_CLONE_URL || (cd ~/$GIT_REPO_NAME ; git fetch --all ; git reset --hard origin/$BRANCH)"

            ADMIN_GIT_REPO_NAME=PSGEL260-sas-viya-4.0.1-administration
            ADMIN_GIT_CLONE_URL=https://gelgitlab.race.sas.com/GEL/workshops/PSGEL260-sas-viya-4.0.1-administration.git
            sudo -u cloud-user bash -c "cd ~ ; git clone --branch master $ADMIN_GIT_CLONE_URL || (cd ~/$ADMIN_GIT_REPO_NAME ; git fetch --all ; git reset --hard origin/$BRANCH)"


            
			MIGRATION_GIT_REPO_NAME=PSGEL270-sas-viya-migration-and-promotion
            MIGRATION_GIT_CLONE_URL=https://gelgitlab.race.sas.com/GEL/workshops/PSGEL270-sas-viya-migration-and-promotion.git
            sudo -u cloud-user bash -c "cd ~ ; git clone --branch master $MIGRATION_GIT_CLONE_URL || (cd ~/MIGRATION_GIT_REPO_NAME ; git fetch --all ; git reset --hard origin/$BRANCH)"

            # # DEAL with reboots here
            # reboot_file=${RACEUTILS_PATH}/.reboot.txt
            # sudo -u root bash -c "touch $reboot_file"
            # logit "file $reboot_file exists"
            # count=$(cat $reboot_file)
            # logit "the reboot count is now $count"
            # echo "$(($count + 1))"  > $reboot_file
            # logit "after the increment, the count is now $(cat $reboot_file)"



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

