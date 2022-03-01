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
        if [ "$race_alias" == "sasnode01" ]  ;     then

            if [[ "$description" == *"_AUTODEPLOY_"* ]] && [ "$reboot_count" -le "1" ] ; then
                JOB=autodeploy
                if ! tmux has-session -t $JOB
                then
                    tmux new -s $JOB -d
                    tmux rename-window -t $JOB main
                fi
                tmux send-keys -t $JOB " sudo -H -u cloud-user bash -c \" bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/_autodeploy-lab_.sh 2>&1 | tee -a  /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/_autodeploy-lab_.log \" " C-m
            fi
            if [[ "$description" == *"_LAB_DEV_"* ]] && [ "$reboot_count" -le "1" ] ; then
                JOB=labdev
                if ! tmux has-session -t $JOB
                then
                    tmux new -s $JOB -d
                    tmux rename-window -t $JOB main
                fi
                tmux send-keys -t $JOB " sudo -H -u cloud-user bash -c \" bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/_lab_dev.sh 2>&1 | tee -a  /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/_lab_dev.log \" " C-m
            fi
            if [[ "$description" == *"_AUTODEPLOY-LAB_"* ]] && [ "$reboot_count" -le "1" ] ; then
                JOB=labdev
                if ! tmux has-session -t $JOB
                then
                    tmux new -s $JOB -d
                    tmux rename-window -t $JOB main
                fi
                tmux send-keys -t $JOB " sudo -H -u cloud-user bash -c \" bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/_autodeploy-lab_.sh 2>&1 | tee -a  /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/_autodeploy-lab_.log \" " C-m
            fi
            if [[ "$description" == *"_AUTODEPLOY-GELENV_"* ]] && [ "$reboot_count" -le "1" ] ; then
                JOB=gelenv-stable
                if ! tmux has-session -t $JOB
                then
                    tmux new -s $JOB -d
                    tmux rename-window -t $JOB main
                fi
                tmux send-keys -t $JOB " sudo -H -u cloud-user bash -c \" bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/_autodeploy-gelenv_.sh 2>&1 | tee -a  /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/_autodeploy-gelenv_.log \" " C-m
            fi

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

