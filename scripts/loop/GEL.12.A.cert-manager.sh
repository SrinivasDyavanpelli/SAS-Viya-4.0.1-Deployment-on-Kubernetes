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

        if [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ; then

        if helm list --all-namespaces | grep -q 'cert-manager'
        then
            sudo -u cloud-user bash -c " helm uninstall cert-manager  --namespace cert-manager ; \
                kubectl delete ns cert-manager "
            sudo -u cloud-user bash -c " kubectl delete crd \
                                            certificaterequests.cert-manager.io \
                                            certificates.cert-manager.io \
                                            challenges.acme.cert-manager.io \
                                            clusterissuers.cert-manager.io \
                                            issuers.cert-manager.io \
                                            orders.acme.cert-manager.io "
        fi

        logit "Installing cert-manager"

        ## extra pre-work for rancher and for Viya 4 TLS
        sudo -u cloud-user bash -c " \
            kubectl create namespace cert-manager ; \
            helm repo add jetstack https://charts.jetstack.io ; \
            helm repo update ; \
            helm install    cert-manager \
                jetstack/cert-manager    \
                --namespace cert-manager   \
                --version v1.0.3 \
                --set installCRDs=true \
                --set extraArgs='{--enable-certificate-owner-ref=true}'   ; \
            "


        logit "cert-manager has been installed"

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

