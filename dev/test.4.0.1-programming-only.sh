#!/bin/bash

# on openshift
##     scp ./SAS_Viya_deployment_data.zip cloud-user@pdcesx03190.race.sas.com:~/


rm -rf ~/viya4
mkdir -p ~/viya4


cp ~/smpk8s-testing/orders/* ~/viya4/

cd ~/viya4
ls -al

mkdir -p ~/viya4/default
mkdir -p ~/viya4/programming

mv SASdeployment-*-default-kustomize*.tgz  ~/viya4/default/
mv SASdeployment-*-programming-kustomize*.tgz  ~/viya4/programming/

cd ~/viya4/programming
tar xvfz SASdeployment-*-programming-kustomize*.tgz

ls -al ~/viya4

kubectl create ns viya4po
kubectl get ns

MASTER_NODE=$(kubectl get nodes -o wide | grep -v NAME | awk  '{print $1 }'  )
echo $MASTER_NODE


bash -c "cat << EOF > ~/viya4/programming/kustomization.yaml
resources:
- bases/sas
- overlays/network/ingress
transformers:
- overlays/required/transformers.yaml
configMapGenerator:
- name: ingress-input
  behavior: merge
  literals:
  - INGRESS_HOST=viya4po.${MASTER_NODE}
- name: input
  behavior: merge
  literals:
  - IMAGE_REGISTRY=gelregistry.exnet.sas.com:5001
- name: sas-shared-config
  behavior: merge
  literals:
  - SAS_URL_SERVICE_TEMPLATE=http:name-of-namespace.name-of-Kubernetes-cluster-master-node:port
EOF"


cd ~/viya4/programming

kustomize build > base.yaml

find . -name "*.*ml"


sed -i.bak 's|cr.sas.com/.*-testready|gelregistry.exnet.sas.com:5001/09qh4z|g' base.yaml
sed -i.bak 's|IfNotPresent|Always|g' base.yaml


grep -ir IMAGE_REGISTRY *
grep -ir  image\: base.yaml

# ./kustomizer.sh --customer-like

#    curl -sk https://gitlab.sas.com/convoy/devops/kustomizations/-/archive/master/kustomizations-master.tar.gz -o kustomizations-master.tar.gz

#    scp ./kustomizations-master.tar.gz cloud-user@pdcesx02107.race.sas.com:~/


kubectl delete -n viya4po -f base.yaml

kubectl apply -n viya4po -f base.yaml

watch kubectl get pods --all-namespaces

## needs some kubectl proxy while I work on ingress.
# kubectl proxy --address $(hostname -i | awk '{print $1;}' ) --accept-hosts='^.*'

# sudo -E /usr/local/bin/kubectl -n fumi01 port-forward --address 0.0.0.0  sas-viya-httpproxy-0 80:8080
kubectl -n viyapo port-forward --address 0.0.0.0  dkrsas 80:8080

exit
# gelregistry.exnet.sas.com:5001/09qh4z/vcmnfnd-240.0.0-x64_redhat_linux_7-docker-testready/sas-cas-administration:1.17.17-20200121.1579622730578
# gelregistry.exnet.sas.com:5001/09qh4z/                                                    sas-cas-administration:1.17.17-20200121.1579622730578