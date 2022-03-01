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

function install_codimd () {

# https://hub.helm.sh/charts/codimd/codimd

kubectl delete ns codimd
kubectl create ns codimd


tee  /tmp/codimd_values.yaml > /dev/null << EOF
---
storageClass: nfs-client
ingress:
  enabled: true
  hosts:
    - host: codimd.$(hostname -f)
      paths:
      - /
EOF

helm repo add codimd https://helm.codimd.dev/

 helm uninstall codimd \
    --namespace codimd

 helm install codimd \
    codimd/codimd --version 0.1.7 \
     -f /tmp/codimd_values.yaml \
    --namespace codimd





}


case "$1" in
    'enable')

    ;;
    'dev')

    ;;

    'start')

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
