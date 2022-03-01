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

function InstallAnsible () {

if [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ;     then
    logit "Installing Ansible but only on sasnode01"
    bash -x /opt/raceutils/scripts/setup.ansible.sh

    logit "We need to setup a decent inventory for the collection"
    # INVENTORY=$(SIMSService --status=any  | awk -F'[ :]' '{print $2 " ansible_host=" $1}'  | grep -v sasclient | sort)
    INVENTORY_SASNODE=$(SIMSService --status=any | grep sasnode | awk -F'[ :]' '{print $2 }' | grep -v sasclient | sort)
    INVENTORY_OTHER=$(SIMSService --status=any | grep -v sasnode | awk -F'[ :]' '{print $2 }' | grep -v sasclient | sort)

    #printf "$INVENTORY" | tee /home/cloud-user/collection/inventory.ini
    ansible localhost -m blockinfile -b -a "dest=/etc/ansible/hosts block=\"[sasnodes]\n${INVENTORY_SASNODE}\"  marker=\"# ansible-managed sasnode block\"  " --diff
    ansible localhost -m blockinfile -b -a "dest=/etc/ansible/hosts block=\"[other]\n${INVENTORY_OTHER}\"  marker=\"# ansible-managed other block\"  " --diff

    logit "Testing out ansible ping"
    sudo -u cloud-user bash -c "ansible all -m ping"

    ## Update the sudoers file so that /usr/local/bin can be used:
    sudo -u cloud-user bash -c "ansible sasnode* \
    -b --become-user=root \
    -m lineinfile \
    -a \
        \"dest=/etc/sudoers \
        regexp='^Defaults    secure_path' \
        line='Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin' \
        state=present \
        backup=yes \" \
        --diff"


    # sudo -u cloud-user bash -c "ansible localhost -b  \
    # -m lineinfile \
    # -a \"dest=/home/cloud-user/.bashrc \
    #     regexp='HISTCONTROL' \
    #     line='export HISTCONTROL=ignoredups:erasedups' \
    #     state=present \
    #     backup=yes \" \
    #     --diff"

    # sudo -u cloud-user bash -c "ansible localhost -b  \
    # -m lineinfile \
    # -a \"dest=/home/cloud-user/.bashrc \
    #     regexp='shopt' \
    #     line='shopt -s histappend' \
    #     state=present \
    #     backup=yes \" \
    #     --diff"

    # sudo -u cloud-user bash -c "ansible localhost -b  \
    # -m lineinfile \
    # -a \"dest=/home/cloud-user/.bashrc \
    #     regexp='PROMPT_COMMAND' \
    #     line='export PROMPT_COMMAND=\' history -a ; history -c ; history -r ; \\\${PROMPT_COMMAND} \' ' \
    #     state=present \
    #     backup=yes \" \
    #     --diff"

fi

}





case "$1" in
    'enable')
        InstallAnsible
        # don't delete ansible yet
       # sudo pip uninstall ansible -y
        # I am disabling this because it's going to cause more issues when multiple people are using the same account.
        # if [ "$race_alias" = "sasnode01" ] ; then


            # sudo -u cloud-user bash -c "ansible localhost -b  \
            # -m lineinfile \
            # -a \"dest=/home/cloud-user/.bashrc \
            #     regexp='HISTCONTROL' \
            #     line='export HISTCONTROL=ignoredups:erasedups' \
            #     state=absent \
            #     backup=yes \" \
            #     --diff"

            # sudo -u cloud-user bash -c "ansible localhost -b  \
            # -m lineinfile \
            # -a \"dest=/home/cloud-user/.bashrc \
            #     regexp='shopt' \
            #     line='shopt -s histappend' \
            #     state=absent \
            #     backup=yes \" \
            #     --diff"

            # sudo -u cloud-user bash -c "ansible localhost -b  \
            # -m lineinfile \
            # -a \"dest=/home/cloud-user/.bashrc \
            #     regexp='PROMPT_COMMAND' \
            #     line='export PROMPT_COMMAND=\' history -a ; history -c ; history -r ; \\\${PROMPT_COMMAND} \' ' \
            #     state=absent \
            #     backup=yes \" \
            #     --diff"

        # fi

    ;;
    'start')
        InstallAnsible

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

