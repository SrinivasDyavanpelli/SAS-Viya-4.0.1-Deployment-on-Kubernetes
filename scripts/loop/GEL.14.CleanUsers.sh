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

        if  [ "$race_alias" == "sasnode01" ] ; then

        logit "About to clean users"
            # Delete the groups and users to free up 1001 for the sas account
            # sudo -u cloud-user bash -c "ansible localhost -m user -a 'name=demofrarpo state=absent' -b"
            # sudo -u cloud-user bash -c "ansible localhost -m user -a 'name=student state=absent' -b"
            #sudo -u cloud-user bash -c "ansible localhost -m user -a 'name=democanepg state=absent' -b"
            #sudo -u cloud-user bash -c "ansible localhost -m group -a 'name=demofrarpo state=absent' -b"
            # sudo -u cloud-user bash -c "ansible localhost -m group -a 'name=student state=absent' -b"
            #sudo -u cloud-user bash -c "ansible localhost -m group -a 'name=democanepg state=absent' -b"

            ## delete the default demo accounts
            sudo -u cloud-user bash -c "ansible sasnode* -m 'shell' -b -a \
                'badUsersList=(`cat /etc/passwd | grep -E \"demo|student\" | cut -d \":\" -f1`); for t in \"\${badUsersList[@]}\"; do userdel -r -f \$t; done;' "

            # a stray command has sometimes put root in the docker group. this puts it back to normal.
            sudo -u cloud-user bash -c "ansible sasnode* -m user  -a \"name=root group=root state=present\" -b --diff"


        logit "Done cleaning users"

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

# docker run -d --name rancher-gui --restart=unless-stopped -p 1080:80 -p 10443:443 rancher/rancher
# docker exec -ti rancher-gui reset-password

# echo "http://$(hostname -f):1080/"

