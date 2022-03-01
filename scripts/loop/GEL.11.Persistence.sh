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

function openEBS () {

ansible sasnode* -b  -m    shell \
    -a " yum install iscsi-initiator-utils -y ; \
         systemctl enable --now iscsid ;\
         systemctl start iscsid ; \
        systemctl status iscsid"

kubectl create ns openebs

helm install \
     --namespace openebs \
     openebs \
     stable/openebs \
      --version 1.10.0

# helm install \
#     stable/nfs-server-provisioner \
#     --namespace=<ns-nfs-wordpress1> \
#     --name=<release-name> \
#     --set=persistence.enabled=true,\
#         persistence.storageClass=<openebs-cstor-sc>,\
#         persistence.size=<cStor-volume-size>,\
#         storageClass.name=<nfs-sc-name>,\
#         storageClass.provisionerName=openebs.io/nfs

}

function minio () {


kubectl delete ns minio
kubectl create ns minio

tee  /tmp/minio.values.yaml > /dev/null << EOF
---
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
  path: /
  hosts:
    - minio.$(hostname -f)
accessKey: "erwan"
secretKey: "lnxsas123"
mode: distributed
replicas: 8
buckets:
  - name: viyabucket1
    policy: none
    purge: false
  - name: viyabucket2
    policy: none
    purge: false
EOF

helm install minio \
    --namespace minio \
    -f /tmp/minio.values.yaml \
    stable/minio


# helm install minio \
#     --namespace minio \
#     --set ingress.enabled=true \
#      --set ingress.hosts[0]=minio.$(hostname -f) \
#     --set mode=distributed,replicas=8 \
#     --set accessKey=erwan \
#     --set secretKey=lnxsas123 \
#     --set buckets[0].name=viyabucket \
#     --set buckets[0].policy=none \
#     --set buckets[0].purge=false \
#     #--set ingress.annotations[0]="nginx.ingress.kubernetes.io/proxy-body-size: 0" \
#     stable/minio

 kubectl get all,ing -n minio

## install client
  ansible localhost \
    -b --become-user=root \
    -m get_url \
    -a \
        "url=https://dl.min.io/client/mc/release/linux-amd64/mc \
        dest=/usr/local/bin/mc \
        validate_certs=no \
        force=yes \
        owner=root \
        mode=0755 \
        backup=yes" \
    --diff

mc --help

mc config host add minio http://minio.$(hostname -f)/ erwan lnxsas123 --api S3v4

mc ls minio

mkdir -p /tmp/data/
cd /tmp/data

curl -o /tmp/data/insight_toy_company_2017.zip https://raw.githubusercontent.com/sascommunities/sas-global-forum-2019/master/4046-2019-SAS-VA-Challenge/insight_toy_company_2017.zip
unzip -u insight_toy_company_2017.zip
curl -o /tmp/data/Calcium.csv  https://raw.githubusercontent.com/sascommunities/sas-global-forum-2019/master/2991-2019-DelGobbo/Files/Calcium.csv

# mc cp /tmp/Calcium.csv minio/viyabucket1/
# mc cp /tmp/insight_toy_company_2017.sas7bdat minio/viyabucket1/

mc mirror --overwrite /tmp/data/  minio/viyabucket1/data/

mc sql --query "select * from S3Object" minio/viyabucket1/data/Calcium.csv
mc sql --query "select count(*) from S3Object" minio/viyabucket1/data/Calcium.csv
#mc sql --query "select avg('Age in AGEU at RFSTDTC') from S3Object group by Sex" minio/viyabucket1/data/Calcium.csv

mc share download minio/viyabucket1/data/Calcium.csv
mc share upload minio/viyabucket1/data/Calcium.csv

}



## Read in the id file. only really needed if running these scripts in standalone mode.
source <( cat /opt/raceutils/.bootstrap.txt  )
source <( cat /opt/raceutils/.id.txt  )
reboot_count=$(cat /opt/raceutils/.reboot.txt)

case "$1" in
    'enable')
        logit "cleaning /srv/nfs/kubedata"
        sudo  rm -rf  /srv/nfs/kubedata/*

    ;;
    'start')

        logit "setting up persistence"
        #NFS_SERVER='sasnode01'
        #NFS_SERVER='intnode01'

        if  [ "$collection_size" = "2"  ] ; then
            NFS_SERVER='sasnode01'
        else
            NFS_SERVER='intnode01'
        fi

        if  [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -gt "1" ] ;     then
            sudo -u root bash -c "systemctl restart nfs-server "
        fi

        if  [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ;     then
            logit "setting up persistence"

            sudo -u cloud-user bash -c "kubectl get storageclass"

            sudo -u root bash -c "ansible localhost  \
            -b -m file \
            -a \"path=/srv/ \
                owner=nfsnobody \
                group=nfsnobody \
                state=directory \
                mode=0755\" \
            --diff"

            sudo -u root bash -c "ansible localhost  \
            -b -m file \
            -a \"path=/srv/nfs/ \
                owner=nfsnobody \
                group=nfsnobody \
                state=directory \
                mode=0755\" \
            --diff"

            sudo -u root bash -c "ansible localhost  \
            -b -m file \
            -a \"path=/srv/nfs/kubedata/ \
                owner=nfsnobody \
                group=nfsnobody \
                state=directory \
                mode=0755\" \
            --diff"

            sudo -u cloud-user bash -c "ansible localhost -b -m service -a \"name=rpcbind    state=started enabled=yes\" "
            sudo -u cloud-user bash -c "ansible localhost -b -m service -a \"name=nfs-lock   state=started enabled=yes\" "
            sudo -u cloud-user bash -c "ansible localhost -b -m service -a \"name=nfs-idmap  state=started enabled=yes\" "


sudo bash -c 'cat << EOF > /etc/exports
/srv/nfs/kubedata     *(rw,sync,no_subtree_check,no_root_squash,insecure)
EOF'

            sudo exportfs -r
            # sudo -u cloud-user bash -c "ansible localhost -b -m service -a 'name=nfs-server state=restarted enabled=yes' "
            sudo -u root bash -c "systemctl restart nfs-server "

            # sudo systemctl restart nfs-server

            ## Could this be the cause of my issues?
            #sudo sed -i '/After=/ s/$/ nfs-server.service/' /usr/lib/systemd/system/docker.service
            #sudo sed -i '/Requires=/ s/$/ nfs-server.service/' /usr/lib/systemd/system/docker.service
            sudo systemctl daemon-reload

            if helm list --all-namespaces | grep -q 'nfs'
            then
                sudo -u cloud-user bash -c "helm uninstall  nfs --namespace nfs"

            fi
            if kubectl get ns | grep -q 'nfs\ '
            then
                kubectl delete ns nfs
            fi

            sudo -u cloud-user bash -c "kubectl create ns nfs"
            # kubectl apply -n nfs -f ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/persistence/pers.yml

            sudo -u cloud-user bash -c "helm repo add stable https://kubernetes-charts.storage.googleapis.com/ ;\
                                        helm repo update"

            # doc: https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner
            sudo -u cloud-user bash -c "helm install  nfs \
                --set nfs.server=${NFS_SERVER} \
                --set nfs.path=/srv/nfs/kubedata \
                --namespace nfs \
                --version  1.2.10 \
                --set storageClass.archiveOnDelete=false \
                --set storageClass.defaultClass=true \
                stable/nfs-client-provisioner"

            ## we need to wait until we see the 2 storage classes
            # sudo -u cloud-user bash -c "while [[ $(kubectl -n nfs  get pods -l app=nfs-client-provisioner -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != \"True\" ]]; do echo \"waiting for pod\" && sleep 1; done"

            wait_for_nfs () {
                echo  "wait for the pod"

                # this seems to loop forever.
                #while [[ $(kubectl -n nfs  get pods -l app=nfs-client-provisioner -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do echo "waiting for pod" && sleep 1; done
                pod_name=$(kubectl -n nfs get pod | grep -v NAME | awk  '{ print $1 }')
                kubectl -n nfs wait --for=condition=Ready --timeout=32s  pod/$pod_name

                echo  "wait for the SC"

                ## if there is a local storage class, it can't be the default.
                if kubectl get storageclasses | grep -q 'local-path'
                then
                    kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
                fi
            }

            sudo -u cloud-user bash -c "$(declare -f wait_for_nfs); wait_for_nfs"



            sudo -u cloud-user bash -c "kubectl get storageclass"
            sudo -u cloud-user bash -c "kubectl -n nfs get all,pvc,ing"

            # sudo -u cloud-user bash -c "kubectl -n nfs describe pod "

        fi
        logit " persistence is done"

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

