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

    'start')
        logit "Skipping the Weave install"
        logit "If you want to install it, run bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.13.Weave.sh deploy"

    ;;

    'deploy')

        if  [ "$collection_size" -gt "2"  ] && [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ]; then



        # helm install my-weave --namespace weave stable/weave-scope

        if helm list --all-namespaces | grep -q 'weave'
        then
            sudo -u cloud-user bash -c "  helm uninstall my-weave --namespace weave   "
        fi
        if kubectl get ns | grep -q 'weave\ '
        then
            kubectl delete ns weave
        fi


        logit "Installing weave "

        ## extra pre-work for rancher
        sudo -u cloud-user bash -c " kubectl create namespace weave "
        sudo -u cloud-user bash -c "helm repo add stable https://kubernetes-charts.storage.googleapis.com/"
        sudo -u cloud-user bash -c "helm repo update"

sudo -u cloud-user bash -c "cat << EOF > /tmp/weave.yaml
global:
  service:
    port: 80
    type: "ClusterIP"
weave-scope-frontend:
  enabled: true
  ingress:
    enabled: true
    paths: [/]
    hosts:
      - weave.$(hostname -f)
EOF"

        sudo -u cloud-user bash -c "  helm install my-weave --namespace weave \
            -f /tmp/weave.yaml \
            stable/weave-scope  "

        # printf "\n* [Weave URL (HTTP**S**)](https://weave.$(hostname -f)/ )\n\n" | \
            # tee -a /home/cloud-user/urls.md
        sudo -u cloud-user bash -c "rm -f /tmp/weave.yaml"

        logit "Weave has been installed"



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

