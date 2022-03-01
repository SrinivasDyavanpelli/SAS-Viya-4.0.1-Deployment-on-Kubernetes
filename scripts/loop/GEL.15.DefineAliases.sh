
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

create_alias_file(){

sudo -u cloud-user bash -c  "cat > /home/cloud-user/.gel_aliases << EOF

alias gel_wait_for_viya4=\" gel_OKViya4 --wait \"

alias gel_bounce_docker=\"   ansible sasnode* -b -m shell   -a 'systemctl reset-failed docker.service' ;  ansible sasnode* -b -m service -a 'name=containerd state=restarted enabled=yes' ;     ansible sasnode* -b -m service -a 'name=docker state=restarted enabled=yes' ;     ansible sasnode* -b -m service -a 'name=docker state=restarted enabled=yes'  \"

alias gel_check_bootstrap=\"sudo journalctl -u bootstrap.collection.service --no-pager \"

alias gel_generate_playpen=\"bash ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/generate.playpen.sh \"

EOF"

}

case "$1" in
    'enable')

    ;;
    'dev')

    ;;

    'start')

        if [ "$race_alias" == "sasnode01" ]  ;     then

        create_alias_file

        # echo $wait_for_viya4
        # sudo  -u cloud-user bash -c '  wait_for_viya4="alias wait_for_viya4=\"bash gel_OKViya4 -n viya4 --wait\" " ; \
        ansible localhost -m lineinfile \
            -a "dest=/home/cloud-user/.bashrc \
                line='. ~/.gel_aliases' \
                state=present" \
            --diff

        sudo -u cloud-user bash -c  "mkdir -p ~/project/"

        # ## Install OKViya4 as gel_OKViya4
        BRANCH=Alpha_0.018
        OKViya4_URL=https://gelgitlab.race.sas.com/GEL/utilities/gel_OKViya4/-/raw/${BRANCH}/gel_OKViya4.sh
        ansible localhost \
            -b --become-user=root \
            -m get_url \
            -a  "url=${OKViya4_URL} \
                dest=/usr/local/bin/gel_OKViya4 \
                validate_certs=no \
                force=yes \
                owner=root \
                mode=0755 \
                backup=yes" \
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
