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

        if  [ "$collection_size" = "2"  ] ; then

            k3s-uninstall.sh

            sudo -u cloud-user bash -c "ansible sasnode* -m shell -b -a 'docker container ls -a'"

            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'systemctl stop docker' "
            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'systemctl stop containerd' "

            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'pkill containerd-shim' "

            sudo -u cloud-user bash -c "ansible sasnode* -m shell -b -a ' docker rm -f \$(docker ps -qa) ; \
            docker volume rm -f \$(docker volume ls -q) ; \
            cleanupdirs=\"/var/lib/etcd /etc/kubernetes /etc/cni /opt/cni /var/lib/cni /var/run/calico /opt/rke\" ; \
            for dir in \$cleanupdirs; do  \
            rm -rf \$dir ;\
            done '"


        fi

        if  [ "$race_alias" == "sasnode01" ] ; then

            if  [ "$collection_size" -gt "2"  ] ; then
                sudo -u cloud-user bash -c "rke remove --force --config /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/RKE_cluster.yml || echo 'no rke' "
            fi

            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'systemctl start docker' "

            sudo -u cloud-user bash -c "ansible sasnode* -m shell -b -a 'docker container ls -a'"

            sudo -u cloud-user bash -c "ansible sasnode* -m shell -b -a ' docker rm -f \$(docker ps -qa) ; \
            docker volume rm -f \$(docker volume ls -q) ; \
            cleanupdirs=\"/var/lib/etcd /etc/kubernetes /etc/cni /opt/cni /var/lib/cni /var/run/calico /opt/rke\" ; \
            for dir in \$cleanupdirs; do  \
            rm -rf \$dir ;\
            done '"
        # ansible sasnode* -b -m shell -a "for mount in $(mount | grep tmpfs | grep '/var/lib/kubelet' | awk '{ print $3 }') /var/lib/kubelet /var/lib/rancher; do umount $mount; done"

            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'docker image prune -a --force ' "
            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'docker system df' "

            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'systemctl stop docker' "
            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'systemctl stop containerd' "

        # stolen from k3s: need to unmount properly
        # do_unmount() {
        #     { set +x; } 2>/dev/null
        #     MOUNTS=
        #     while read ignore mount ignore; do
        #         MOUNTS="$mount\n$MOUNTS"
        #     done </proc/self/mounts
        #     MOUNTS=$(printf $MOUNTS | grep "^$1" | sort -r)
        #     if [ -n "${MOUNTS}" ]; then
        #         set -x
        #         umount ${MOUNTS}
        #     else
        #         set -x
        #     fi
        # }

        # do_unmount '/run/k3s'
        # do_unmount '/var/lib/rancher/k3s'
        # do_unmount '/var/lib/kubelet/pods'
        # do_unmount '/run/netns/cni-'


            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'pkill containerd-shim' "
            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'systemctl daemon-reload' "


            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'yum remove docker-ce docker-ce-cli -y ' "

            sudo -u cloud-user bash -c "ansible  sasnode* -b  -m shell -a 'rm -rf /var/lib/docker /usr/local/bin/rke' "

        fi


    ;;
    'start')

        ## RKE
        if  [ "$collection_size" -gt "2"  ] ; then
            logit "We are running on a multi-machine collection with $collection_size servers"

            logit "Installing RKE"

            if [ "$race_alias" == "sasnode01" ] && [ "$reboot_count" -le "1" ] ; then
                logit "on sasnode01"

                # #ansible  sasnode*  -b -m shell -a "curl https://releases.rancher.com/install-docker/18.09.2.sh | sh"
                # ansible  sasnode*  -m shell -a "docker --version"
                # ansible  sasnode*  -b -m shell -a "usermod -aG docker cloud-user"

                sudo -u cloud-user bash -c "ansible sasnode* \
                        -b --become-user=root \
                        -m get_url \
                        -a \
                            \"url=https://github.com/rancher/rke/releases/download/v1.1.6/rke_linux-amd64 \
                            dest=/usr/local/bin/rke \
                            validate_certs=no \
                            force=yes \
                            owner=root \
                            mode=0755 \
                            backup=yes\" \
                            --diff"

                sudo -u cloud-user bash -c "ansible  sasnode*   -m shell -a 'rke --version'"

                sudo -u cloud-user bash -c "ansible-playbook /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/generate_RKE_Cluster_file.yaml"

                sudo -u cloud-user bash -c "time rke up --config /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/RKE_cluster.yaml"
                # export KUBECONFIG=$(pwd)/kube_config_rancher-cluster.yml

                sudo -u cloud-user bash -c "rm -rf /home/cloud-user/.kube/*"
                sudo -u cloud-user bash -c "cp /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/kube_config_RKE_cluster.yaml /home/cloud-user/.kube/config"

                ## this creates a portable version of the config file.
                sudo -u cloud-user bash -c "cat ~/.kube/config \
                    | sed \"s|intnode03|$(ssh -o StrictHostKeyChecking=no intnode03 hostname -f)|g\" \
                    > ~/.kube/config_portable"

                # change the name so it's better for lens
                sudo -u cloud-user bash -c " cd ~/.kube ; \
                    sed -i.bak  \"s|\"gelcluster\"|"\"gelcluster.$(hostname -f)\""|g\" ~/.kube/config_portable"

                logit "Installed RKE version $(sudo -u cloud-user bash -c 'kubectl version --short')"

            fi
        fi

    ### K3S
        if  [ "$collection_size" = "2"  ] ; then

            if [ "$reboot_count" -le "1" ]  ; then
                logit "Reboot Count is $reboot_count "

                logit "Start installing K3S"
                k3s-uninstall.sh

                K8S_VERSION=v1.18.10+k3s1

                time curl -sfL https://get.k3s.io |  \
                    INSTALL_K3S_VERSION="$K8S_VERSION" \
                    K3S_KUBECONFIG_MODE="666"  \
                    INSTALL_K3S_EXEC=" --docker --kubelet-arg=max-pods=500 --kube-apiserver-arg=service-node-port-range=80-40000 --no-deploy traefik"  \
                    sh -s -

                sudo -u cloud-user bash -c "mkdir -p ~/.kube ; \
                                            rm -f ~/.kube/config ; \
                                            ln -s /etc/rancher/k3s/k3s.yaml ~/.kube/config "

                logit "Installed K3S version $(sudo -u cloud-user bash -c 'kubectl version --short')"

            fi
        fi

    ### make sure root has the same level of access:
        sudo -u root bash -c "mkdir -p ~/.kube ;   rm -f /root/.kube/config ; cp /home/cloud-user/.kube/config  /root/.kube/config "

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


# sudo mkdir -p /var/lib/rancher/k3s/server/manifests/
# sudo bash -c "cat << EOF > /var/lib/rancher/k3s/server/manifests/custom-traefik.yaml
# apiVersion: helm.cattle.io/v1
# kind: HelmChart
# metadata:
#   name: traefik
#   namespace: kube-system
# spec:
#   chart: https://%{KUBERNETES_API}%/static/charts/traefik-1.81.0.tgz
#   set:
#     rbac.enabled: 'true'
#     ssl.enabled: 'true'
#     metrics.prometheus.enabled: 'true'
#     kubernetes.ingressEndpoint.useDefaultPublishedService: 'true'
#     dashboard.enabled: 'true'
#     dashboard.domain: 'traefikdashboard.$(hostname -f)'
# EOF"

                #bash -x /opt/raceutils/scripts/setup.k3s.sh --reset
                # time curl -sfL https://get.k3s.io |     INSTALL_K3S_VERSION="$K8S_VERSION"  K3S_KUBECONFIG_MODE="644"   INSTALL_K3S_EXEC=" --docker --kubelet-arg=max-pods=500 --no-deploy traefik"   sh -s -

