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

        sudo -u root bash -c "rm -f /etc/systemd/system/collection.bootstrap.service "
        sudo rm -rf /etc/openldap/
        #sudo -u cloud-user bash -c "ansible  sasnode*  -b -m shell -a 'usermod -g root root' "
        sudo -u root bash -c "usermod -g root root "
        id root

    ;;
    'start')

        sudo -u root bash -c "rm -f /etc/systemd/system/collection.bootstrap.service "

        sudo yum install socat jq bash-completion git tmux htop dstat unzip nfs-utils tree ncdu -y

        sudo yum update containerd containerd.io -y

## make tmux useful with a mouse:
# sudo -u cloud-user bash -c "cat << EOF > ~/.tmux.conf
# # Make mouse useful in copy mode
# setw -g mode-mouse on
# # Allow mouse to select which pane to use
# set -g mouse-select-pane on
# # Allow mouse dragging to resize panes
# set -g mouse-resize-pane on
# # Allow mouse to select windows
# set -g mouse-select-window on
# # Scroll History
# set -g history-limit 30000
# # Set ability to capture on start and restore on exit window data when running an application
# setw -g alternate-screen on
# # Lower escape timing from 500ms to 50ms for quicker response to scroll-buffer access.
# set -s escape-time 50
# EOF"

        logit "Setup the GEL registry Certs"
        bash -x /opt/raceutils/scripts/apply.gelregistry.certs.sh

        if [ "$race_alias" = "sasnode01" ] ; then
            echo "$(datestamp) $(timestamp): Generate Public Key " >> ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
            sudo -u cloud-user bash -c "echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhw9+kXjLMdi1AnzYVfBbCa4L6cC1ebiW7UuAMB6vQUTMGHwrBRBbVZ23E2VdUsEGtEUk4qD1rpZRTrJRwnmaY3iEfRSOcrif1FOq8116r0unov8ne2RRYEI+PEYNCEnx/EiH38UBiNcsCxtNnW2BO3Cdq9nLzRjZr+OVookSCMlcFIiiMeMEh58F/Cx5LTt0LNUn4sgrnYHaoLtLvjddz9+igOKITnbIcNM2GK3ZkTdVZcfSeOyJUjcgdfqS7pG+o2DViMPv1Ttexu6s/aa1YuINvdWZOY/DYNyU0HF5ccOc9ewiiCTq0GU06dI1qWwoijiaZa808OwoZuvmWBlIz'  > ~/.ssh/cloud-user_id_rsa.pub"
            sudo pip install Pygments icdiff
        fi

        # Update GIT
        function install_git2 () {
        # Update GIT
        git --version
        # git version 1.8.3.1
        sudo yum -y remove git*
        # sudo yum -y install https://centos7.iuscommunity.org/ius-release.rpm   # Modified by cangxc - Tested with sasgnn
        sudo yum -y install https://repo.ius.io/ius-release-el7.rpm
        #sudo yum -y install git2u-all
        sudo yum -y install git224-all
        git --version
        # git version 2.16.5
        }
        ## commented out because no worky
        install_git2


        sudo -u cloud-user bash -c "sudo pip install yamllint"

        # the saved collection has a stray folder that can cause issues.
        if [ "$reboot_count" -le "1" ] ; then
            sudo rm -rf /etc/openldap/
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

