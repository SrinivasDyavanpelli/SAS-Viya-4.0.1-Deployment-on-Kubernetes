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

        if  [ "$race_alias" == "sasnode01" ] ; then

            sudo rm -f /usr/local/bin/kubectl

            ansible localhost \
                -m lineinfile \
                -a "dest=~/.bashrc \
                    line='source <(kubectl completion bash)' \
                    state=absent" \
                --diff
        fi

    ;;
    'dev')

    ;;

    'start')
        if [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ;     then

        ### KUBECTL
        ansible localhost \
            -b --become-user=root \
            -m get_url \
            -a \
                "url=https://storage.googleapis.com/kubernetes-release/release/v1.18.6/bin/linux/amd64/kubectl \
                dest=/usr/local/bin/kubectl \
                validate_certs=no \
                force=yes \
                owner=root \
                mode=0755 \
                backup=yes" \
                    --diff

        sudo -u cloud-user bash -c "ansible localhost \
            -b -m yum \
            -a \"name=bash-completion \
                state=present\" \
            --diff "


        ## bash completion for kubectl
        sudo -u cloud-user bash -c "ansible localhost \
            -m lineinfile \
            -a \"dest=~/.bashrc \
                line='source <(kubectl completion bash)' \
                state=present\
                insertafter=EOF\" \
            --diff "

        logit "install bash completion for kubectl"

        ### Stern - multi-log tool
        ansible localhost \
            -b --become-user=root \
            -m get_url \
            -a \
                "url=https://github.com/wercker/stern/releases/download/1.11.0/stern_linux_amd64 \
                dest=/usr/local/bin/stern \
                validate_certs=no \
                force=yes \
                owner=root \
                mode=0755 \
                backup=yes" \
                    --diff

        logit "installed Stern"


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

