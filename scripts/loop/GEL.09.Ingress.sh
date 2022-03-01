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

        if  [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ;     then

        if helm list --all-namespaces | grep -q 'my-nginx'
        then
            sudo -u cloud-user bash -c "   helm uninstall  my-nginx --namespace nginx  "
        fi
        if kubectl get ns | grep -q 'nginx\ '
        then
            kubectl delete ns nginx
        fi

        sudo -u cloud-user bash -c "helm repo add stable https://kubernetes-charts.storage.googleapis.com/"
        sudo -u cloud-user bash -c "helm repo update"

        ## NGINX ingress on 80/443
        sudo -u cloud-user bash -c " kubectl create ns nginx   "

        sudo -u cloud-user bash -c "   helm install  my-nginx --namespace nginx  \
            --set controller.service.type=NodePort \
            --set controller.service.nodePorts.http=80 \
            --set controller.service.nodePorts.https=443 \
            --set controller.extraArgs.enable-ssl-passthrough="" \
            --set controller.autoscaling.enabled=true \
            --set controller.autoscaling.minReplicas=2 \
            --set controller.autoscaling.maxReplicas=5 \
            --version 1.41.2 \
            --set controller.autoscaling.targetCPUUtilizationPercentage=50 \
            --set controller.autoscaling.targetMemoryUtilizationPercentage=50 \
            stable/nginx-ingress "

            ## the ssl-passthrough line is important for argocd to work

        ## TRAEFIK ingress
        function deploy_traefik () {
        if helm list --all-namespaces | grep -q 'traefik'
        then
            sudo -u cloud-user bash -c "helm uninstall  my-traefik --namespace traefik"
            sudo -u cloud-user bash -c "kubectl delete clusterrolebinding permissive-binding "

        fi
        if kubectl get ns | grep -q 'traefik\ '
        then
            kubectl delete ns traefik
        fi

        sudo -u cloud-user bash -c "kubectl create ns traefik"
        sudo -u cloud-user bash -c "kubectl create clusterrolebinding permissive-binding --clusterrole=cluster-admin --user=admin --user=kubelet --group=system:serviceaccounts"

        # https://medium.com/@patrickeasters/using-traefik-with-tls-on-kubernetes-cb67fb43a948
        # openssl req \
        #         -newkey rsa:2048 -nodes -keyout tls.key \
        #         -x509 -days 365 -out tls.crt
        # kubectl create secret generic traefik-cert \
        #         --from-file=tls.crt \
        #         --from-file=tls.key

        # sudo -u cloud-user bash -c "openssl req  -newkey rsa:2048 -nodes -keyout /tmp/tls_traefik.key  -x509 -days 365 -out /tmp/tls_traefik.crt -subj \"/C=US/ST=NC/L=Cary/O=SAS/OU=ContainersTraining/CN=*.$(hostname -f)\""
        # sudo -u cloud-user bash -c "kubectl create secret generic traefik-cert  --from-file=/tmp/tls_traefik.crt   --from-file=/tmp/tls_traefik.key "

        sudo -u cloud-user bash -c " helm install  my-traefik \
            --namespace traefik \
            --set serviceType=NodePort \
            --set service.nodePorts.http=81 \
            --set service.nodePorts.https=444 \
            --set dashboard.enabled=true \
            --set dashboard.domain=traefikdashboard.$(hostname -f) \
            --set ssl.generateTLS=true \
            --set ssl.insecureSkipVerify=true \
            --set accessLogs.enabled=true \
            stable/traefik"

            # --set forwardedHeaders.enabled=true \
            # --set ssl.defaultCN=\"*.$(hostname -f)\" \

        printf "\n* [Traefik Dashboard URL (HTTP )](http://traefikdashboard.$(hostname -f)/ )\n\n" | tee -a /home/cloud-user/urls.md
        printf "\n* [Traefik Dashboard URL (HTTP**S**)](https://traefikdashboard.$(hostname -f)/ )\n\n" | tee -a /home/cloud-user/urls.md
        }

        # deploy_traefik

        #  --set ssl.defaultSANList=\"*.$(hostname -f)\" \
        #     --set ssl.defaultIPList=\"$(hostname -i)\" \
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

