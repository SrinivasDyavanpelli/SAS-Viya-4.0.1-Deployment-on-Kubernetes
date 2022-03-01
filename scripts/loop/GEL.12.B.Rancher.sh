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
         sudo  -u root bash -c 'rm -rf /usr/local/bin/rancher '

    ;;
    'dev')

    ;;

    'start')
        logit "Skipping the Rancher install"
        logit "If you want to install it, run bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.12.Rancher.sh deploy"

    ;;

    'deploy')

        if  [ "$collection_size" -gt "2"  ] && [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ; then

        logit "Installing rancher CLI"

        sudo  -u cloud-user bash -c ' mkdir -p /tmp/rancher'


        sudo -u cloud-user bash -c "ansible localhost \
                -m get_url \
                -a \
                    \"url=https://github.com/rancher/cli/releases/download/v2.4.0-rc4/rancher-linux-amd64-v2.4.0-rc4.tar.gz \
                    dest=/tmp/rancher/rancher.tar.gz \
                    validate_certs=no \
                    force=yes \
                    mode=0755 \
                    backup=yes\" \
                    --diff"

        sudo  -u root bash -c ' cd /tmp/rancher ; \
                tar xvf rancher.tar.gz ; \
                rm -f /usr/local/bin/rancher ; \
                cp -f /tmp/rancher/rancher-v2.4.0-rc4/rancher /usr/local/bin/rancher '


         sudo  -u root bash -c 'rm -rf /tmp/rancher/ '

        sudo  -u root bash -c 'chmod 755 /usr/local/bin/rancher  '


        if helm list --all-namespaces | grep -q 'cattle-system'
        then
            sudo -u cloud-user bash -c " helm uninstall rancher --namespace cattle-system "
        fi

        logit "Installing rancher itself"

        ## extra pre-work for rancher
        sudo -u cloud-user bash -c " kubectl create namespace cattle-system ; \
            kubectl apply -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.12/deploy/manifests/00-crds.yaml
            # kubectl create namespace cert-manager ; \
            # helm repo add jetstack https://charts.jetstack.io ; \
            # helm repo update ; \
            # helm uninstall    cert-manager  --namespace cert-manager ; \
            # helm install    cert-manager jetstack/cert-manager    --namespace cert-manager   --version v0.12.0 ; \
            "

        sudo -u cloud-user bash -c " helm repo add rancher-latest https://releases.rancher.com/server-charts/latest ; \
            helm repo update ; \
            helm uninstall rancher  --namespace cattle-system ;\
            helm install rancher rancher-latest/rancher \
            --namespace cattle-system \
            --set tls=external \
            --set hostname=rancher.$(hostname -f) ; \
            kubectl -n cattle-system rollout status deploy/rancher"


        printf "\n* [Rancher URL (HTTP**S**)](https://rancher.$(hostname -f)/ )\n\n" | tee -a /home/cloud-user/urls.md

        logit "Rancher has been installed"

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

