#!/bin/bash

timestamp() {
  date +"%T"
}
datestamp() {
  date +"%D"
}

function logit () {
    sudo chmod -R 777 ${RACEUTILS_PATH}/logs
    printf "$(datestamp) $(timestamp): $1 \n"  | tee -a ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
}

## Read in the id file. only really needed if running these scripts in standalone mode.
source <( cat /opt/raceutils/.bootstrap.txt  )
source <( cat /opt/raceutils/.id.txt  )

case "$1" in
    'enable')

    ;;
    'start')

        if helm list --all-namespaces | grep -q 'harbor'
        then
            helm uninstall my-harbor --namespace harbor
            kubectl delete pvc --all  -n harbor
        fi
        if kubectl get ns | grep -q 'harbor\ '
        then
            kubectl delete ns harbor
        fi

        kubectl create ns harbor

        helm repo add harbor https://helm.goharbor.io

        helm install my-harbor harbor/harbor \
                    --namespace harbor \
                    --set expose.type=ingress \
                    --set expose.tls.enabled=true \
                    --set expose.ingress.hosts.core=harbor.$(hostname -f) \
                    --set persistence.enabled=true \
                    --set clair.enabled=true \
                    --set externalURL=https://harbor.$(hostname -f)/ \
                    --set harborAdminPassword=lnxsas

        # printf "* [Harbor URL](https://harbor.$(hostname -f)/)\n" \
        #  | tee -a ~/urls.md


            # regexp='insecure-registries' \

        docker login harbor.$(hostname -f):443 -u admin -p lnxsas

    #     # docker login $(hostname -f)
    #     #     u: admin
    #     #     p: lnxsas

         docker pull centos:7
         docker tag centos:7 harbor.$(hostname -f):443/library/centos:7
         docker push  harbor.$(hostname -f):443/library/centos:7



    exit

    # ### K3S
    #     if  [ "$collection_size" -gt "2"  ] ; then

    #         echo harbor
    #         exit


    #         # mkdir -p ~/.kube
    #         # rm -f ~/.kube/config
    #         # ln -s /etc/rancher/k3s/k3s.yaml ~/.kube/config


    #         ## keep at it:
    #         ## https://github.com/goharbor/harbor-helm/blob/master/values.yaml


    #         docker login harbor.$(hostname -f) -u admin -p Harbor12345

    #         docker image pull centos:7
    #         docker image tag centos:7 harbor.$(hostname -f)/library/centos:7
    #         docker image push harbor.$(hostname -f)/library/centos:7

    #         sudo systemctl reload docker
    #         #Harbor12345

    #     else

    #     # remove k3s
    #     k3s-uninstall.sh
    #     sudo systemctl restart docker


    #     sudo yum install docker-compose -y
    #     HARBOR_HTTP=80
    #     HARBOR_HTTPS=443


    #     ## take care of the certs first:

    #     ansible sasnode01,localhost -m file -b -a \
    #     "dest=/registry/ state=directory owner=cloud-user group=cloud-user mode=0755"
    #     ansible sasnode01,localhost -m file -b -a \
    #     "dest=/registry/certs state=directory owner=cloud-user group=cloud-user mode=0755"
    #     ansible sasnode01,localhost -m file -b -a \
    #     "dest=/registry/images state=directory owner=cloud-user group=cloud-user mode=0755"

    #     echo $long_race_hostname

    #     openssl req -newkey rsa:4096 -nodes -sha256 \
    #         -keyout /registry/certs/domain.key -x509 -days 365 \
    #         -out /registry/certs/domain.crt \
    #         -subj "/C=US/ST=NC/L=Cary/O=SAS/OU=Viya4Training/CN=$long_race_hostname"

    #     ## distribute certs:
    #     ansible sasnode*,localhost  \
    #         -b -m file \
    #         -a "path=\"/etc/docker/certs.d/$long_race_hostname:$HARBOR_HTTPS/\" owner=root group=root state=directory mode=0750" \
    #         --diff

    #     ansible sasnode*,localhost  \
    #         -b -m copy \
    #         -a "dest=\"/etc/docker/certs.d/$long_race_hostname:$HARBOR_HTTPS/ca.crt\" \
    #             src=/registry/certs/domain.crt" \
    #         --diff

    #     ## restart docker
    #     ansible sasnode*,localhost  \
    #         -b -m service \
    #         -a "name=docker state=restarted enabled=y" \
    #         --diff



    #     ## get Harbor payload
    #     cd /tmp
    #     sudo rm -rf /tmp/harbor*

    #     ansible localhost \
    #         -m get_url \
    #         -a \
    #             "url=https://github.com/goharbor/harbor/releases/download/v1.10.1-rc1/harbor-offline-installer-v1.10.1-rc1.tgz \
    #             dest=/tmp/harbor-offline-installer-v1.10.1-rc1.tgz \
    #             validate_certs=no \
    #             mode=0755 \
    #             backup=yes" \
    #                 --diff

    #     cd /tmp
    #     tar xvf harbor-offline-installer-v1.10.1-rc1.tgz
    #     cd /tmp/harbor/

    #     ## adjust files
    #     ansible localhost \
    #     -m lineinfile \
    #     -a  "dest=/tmp/harbor/harbor.yml \
    #         regexp='^hostname:' \
    #         line='hostname: $(hostname -f)' \
    #         state=present \
    #         backup=yes " \
    #         --diff

    #     ansible localhost \
    #     -m lineinfile \
    #     -a  "dest=/tmp/harbor/harbor.yml \
    #         regexp='^hostname:' \
    #         line='hostname: $(hostname -f)' \
    #         state=present \
    #         backup=yes " \
    #         --diff

    #     ansible localhost \
    #     -m lineinfile \
    #     -a  "dest=/tmp/harbor/harbor.yml \
    #         regexp='^  private_key:' \
    #         line='  private_key: /registry/certs/domain.key' \
    #         state=present \
    #         backup=yes " \
    #         --diff

    #     ansible localhost \
    #     -m lineinfile \
    #     -a  "dest=/tmp/harbor/harbor.yml \
    #         regexp='^  certificate:' \
    #         line='  certificate: /registry/certs/domain.crt' \
    #         state=present \
    #         backup=yes " \
    #         --diff

    #     ansible localhost \
    #     -m lineinfile \
    #     -a  "dest=/tmp/harbor/harbor.yml \
    #         regexp='^harbor_admin_password:' \
    #         line='harbor_admin_password: lnxsas' \
    #         state=present \
    #         backup=yes " \
    #         --diff

    #     ansible localhost \
    #     -m replace \
    #     -a  "dest=/tmp/harbor/harbor.yml \
    #         regexp='port: 443' \
    #         replace='port: $HARBOR_HTTPS' \
    #         backup=yes " \
    #         --diff


    #     ansible localhost \
    #     -m replace \
    #     -a  "dest=/tmp/harbor/harbor.yml \
    #         regexp='port: 80' \
    #         replace='port: $HARBOR_HTTP' \
    #         backup=yes " \
    #         --diff

    #     ##kick off harbor install

    #     cd /tmp/harbor
    #     #pygmentize harbor.yml

    #     sudo /tmp/harbor/install.sh

    #     printf "* [Harbor URL](https://$(hostname -f):$HARBOR_HTTPS/)\n" | tee -a ~/urls.md

    #     fi

    #     docker login $(hostname -f):443 -u admin -p lnxsas

    #     # docker login $(hostname -f)
    #     #     u: admin
    #     #     p: lnxsas

    #      docker pull centos:7
    #      docker tag centos:7 $(hostname -f)/library/centos:7
    #      docker push  $(hostname -f)/library/centos:7

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

