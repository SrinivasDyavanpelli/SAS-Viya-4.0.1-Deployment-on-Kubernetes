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

sudo tee  /tmp/install_ops4viya.sh > /dev/null << "EOF"
#!/bin/bash

# https://github.com/coreos/kube-prometheus#quickstart
# https://gitlab.sas.com/emidev/ops4viya/

cd  /home/cloud-user/
sudo rm -rf ops4viya*
wget https://gelweb.race.sas.com/scripts/PSGEL255/ops4viya/ops4viya-master.zip
unzip ops4viya-master.zip
mv /home/cloud-user/ops4viya-master /home/cloud-user/ops4viya
rm ops4viya-master.zip

## install monitoring
cd  /home/cloud-user/ops4viya/
export MON_NS=ops4viyamon
kubectl delete ns ${MON_NS}
kubectl create ns ${MON_NS}

export NGINX_NS=nginx

# /home/cloud-user/ops4viya/monitoring/bin/deploy_monitoring_cluster.sh
MON_NS=ops4viyamon /home/cloud-user/ops4viya/monitoring/bin/deploy_monitoring_cluster.sh
 ## you are not seeing double, it only works on the second try. (something with prometheus operator not being ready?)
MON_NS=ops4viyamon /home/cloud-user/ops4viya/monitoring/bin/deploy_monitoring_cluster.sh

printf "\n* [Grafana URL (u=admin p=admin) (HTTP)](http://grafana.$(hostname -f):31100/ )\n\n" | tee -a /home/cloud-user/urls.md
printf "\n* [Prometheus URL (HTTP)](http://prometheus.$(hostname -f):31090/ )\n\n" | tee -a /home/cloud-user/urls.md
printf "\n* [Alert Manager URL (HTTP)](http://alertman.$(hostname -f):31091/ )\n\n" | tee -a /home/cloud-user/urls.md

# deploy the Viya exporter
# in each namespace where Viya will live
# for NS in lab dailymirror testready
# do
#     kubectl create ns $NS
#     cd /home/cloud-user/ops4viya/
#     VIYA_NS=$NS /home/cloud-user/ops4viya/monitoring/bin/deploy_monitoring_viya.sh
# done

## install logging

/home/cloud-user/ops4viya/logging/bin/remove_logging_open.sh
export  LOG_NS=ops4viyalog
kubectl delete ns ${LOG_NS}
kubectl create ns ${LOG_NS}
/home/cloud-user/ops4viya/logging/bin/deploy_logging_open.sh

printf "\n* [Kibana URL (HTTP)](http://kibana.$(hostname -f):31033/app/kibana )\n\n" | tee -a /home/cloud-user/urls.md

EOF

chmod 777 /tmp/install_ops4viya.sh

case "$1" in
    'enable')


    ;;
    'start')

    if  [ "$collection_size" -gt "2"  ] ; then

        if [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ;     then

            JOB=deploy_ops4viya
            if ! tmux has-session -t $JOB
            then
                tmux new -s $JOB -d
                tmux rename-window -t $JOB main
            fi
            tmux send-keys -t $JOB " sudo -u cloud-user bash -c '/tmp/install_ops4viya.sh' " C-m

            logit "Ops4viya deployment kicked of in tmux. Search for  tmux session called $JOB , possibly running as root"

        fi
    fi

    ;;
    'stop')

    ;;
    'clean')
        kubectl delete ns ops4viyalog ops4viyamon

    ;;
    'dev')
    #install_ops4viya
    ;;

    *)
        printf "Usage: GEL.00.Clone.Project.sh {enable/start|stop|clean} \n"
        exit 1
    ;;
esac

