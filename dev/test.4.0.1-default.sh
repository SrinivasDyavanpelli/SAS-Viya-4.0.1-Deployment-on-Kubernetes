#!/bin/bash

# on openshift
##     scp ./SAS_Viya_deployment_data.zip cloud-user@pdcesx03190.race.sas.com:~/
ORDER=09QPCD
cd ~/viya4/$ORDER
#curl -kO http://spsrest.fyi.sas.com:8081/comsat/orders/$ORDER/view/soe/SAS_Viya_deployment_data.zip
#get the hack script
curl -sk https://gitlab.sas.com/convoy/devops/kustomizations/-/archive/master/kustomizations-master.tar.gz -o kustomizations-master.tar.gz

#push to the 3 machines.
scp SAS_Viya_deployment_data.zip cloud-user@rext03-0092.race.sas.com:/home/cloud-user/
scp SAS_Viya_deployment_data.zip cloud-user@pdcesx04205.race.sas.com:/home/cloud-user/
scp SAS_Viya_deployment_data.zip cloud-user@pdcesx02102.race.sas.com:/home/cloud-user/

# push the kustomize to all:
scp *kustomiz* cloud-user@rext03-0092.race.sas.com:/home/cloud-user/
scp *kustomiz* cloud-user@pdcesx04205.race.sas.com:/home/cloud-user/
scp *kustomiz* cloud-user@pdcesx02102.race.sas.com:/home/cloud-user/



kubectl create ns viya4
kubectl get ns

# MASTER_NODE=$(kubectl get nodes -o wide | grep -v NAME | awk  '{print $1 }'  )
MASTER_NODE=$(hostname -f  )
echo $MASTER_NODE


rm -rf ~/viya4
mkdir -p ~/viya4


#cp ~/smpk8s-testing/orders/* ~/viya4/
#copy .tgz file in place

cd ~/viya4/
cp ~/*kustomize*.tgz ~/viya4/
ls -al
cd ~/viya4/

tar xvfz SASdeployment-*kustomize*.tgz


bash -c "cat << EOF > ~/viya4/bundles/default/kustomization.yaml
resources:
- bases/sas
- overlays/network/ingress
transformers:
- overlays/required/transformers.yaml
configMapGenerator:
- name: ingress-input
  behavior: merge
  literals:
  - INGRESS_HOST=viya4.${MASTER_NODE}
- name: input
  behavior: merge
  literals:
  - IMAGE_REGISTRY=pdcesx02102.race.sas.com/library
- name: sas-shared-config
  behavior: merge
  literals:
  - SAS_URL_SERVICE_TEMPLATE=http:name-of-namespace.name-of-Kubernetes-cluster-master-node:port
EOF"

cd ~/viya4/bundles/default
cp ~/kustomizations-master.tar.gz ~/viya4/bundles/default
tar  -xz kustomizations-master.tar.gz --strip-components=1

kustomize build > base.yaml

# sed -i.bak 's|cr.sas.com/vcmnfnd-240.0.0-x64_redhat_linux_7-docker-testready|gelregistry.exnet.sas.com:5001/09qh4z|g' base.yaml
# sed -i.bak 's|cr.sas.com/va-240.0.0-x64_redhat_linux_7-docker-testready|gelregistry.exnet.sas.com:5001/09qh4z|g' base.yaml
# sed -i.bak 's|cr.sas.com/statviya-240.0.0-x64_redhat_linux_7-docker-testready|gelregistry.exnet.sas.com:5001/09qh4z|g' base.yaml

cp base.yaml base.yaml.pre
sed -i.bak "s|cr.sas.com/.*-testready|pdcesx02102.race.sas.com/library|g" base.yaml
# sed -i.bak 's|IfNotPresent|Always|g' base.yaml


grep -ir IMAGE_REGISTRY *
grep -ir  image\: base.yaml

# ./kustomizer.sh --customer-like

kubectl delete -n viya4 -f base.yaml



kubectl apply -n viya4 -f base.yaml
watch kubectl get pods -o wide -n viya4

kubectl -n viya4 scale deployment --all --replicas=0


# gelregistry.exnet.sas.com:5001/09qh4z/vcmnfnd-240.0.0-x64_redhat_linux_7-docker-testready/sas-cas-administration:1.17.17-20200121.1579622730578
# gelregistry.exnet.sas.com:5001/09qh4z/                                                    sas-cas-administration:1.17.17-20200121.1579622730578



printf "\n\n Click on this URL to open VSCode on your server:\n      http://$(hostname -i):8080/ \n"
docker run -it -p 0.0.0.0:8080:8080 -v "/home/cloud-user/viya4/bundles/default/:/home/coder/project/" codercom/code-server

