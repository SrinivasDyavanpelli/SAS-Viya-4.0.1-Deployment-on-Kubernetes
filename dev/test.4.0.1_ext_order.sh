#!/bin/bash

# on openshift
##     scp ./SAS_Viya_deployment_data.zip cloud-user@pdcesx03190.race.sas.com:~/


rm -rf ~/viya4ext
mkdir -p ~/viya4ext


cd ~/viya4ext
ls -al


cd ~/viya4ext/
cp ~/*kustomize*.tgz ~/viya4ext/
ls -al
cd ~/viya4ext/

tar xvfz SASdeployment-*-kustomize*.tgz

ls -al ~/viya4ext

kubectl create ns viya4ext
kubectl get ns

MASTER_NODE=$(hostname -f)
kubectl get nodes -o wide | grep -v NAME | awk  '{print $1 }'
echo $MASTER_NODE


bash -c "cat << EOF > ~/viya4ext/bundles/default/kustomization.yaml
resources:
- bases/sas
- overlays/network/ingress
transformers:
- overlays/required/transformers.yaml
configMapGenerator:
- name: ingress-input
  behavior: merge
  literals:
  - INGRESS_HOST=viya4ext.${MASTER_NODE}
- name: sas-shared-config
  behavior: merge
  literals:
  - SAS_URL_SERVICE_TEMPLATE=http:name-of-namespace.name-of-Kubernetes-cluster-master-node:port
EOF"

cd ~/viya4ext/bundles/default

kustomize build > base.yaml

# sed -i.bak 's|cr.sas.com/vcmnfnd-240.0.0-x64_redhat_linux_7-docker-testready|gelregistry.exnet.sas.com:5001/09qh4z|g' base.yaml
# sed -i.bak 's|cr.sas.com/va-240.0.0-x64_redhat_linux_7-docker-testready|gelregistry.exnet.sas.com:5001/09qh4z|g' base.yaml
# sed -i.bak 's|cr.sas.com/statviya-240.0.0-x64_redhat_linux_7-docker-testready|gelregistry.exnet.sas.com:5001/09qh4z|g' base.yaml

# sed -i.bak 's|cr.sas.com/.*-testready|gelregistry.exnet.sas.com:5001/09qh4z|g' base.yaml
# sed -i.bak 's|IfNotPresent|Always|g' base.yaml
sed -i.bak 's|sas-image-pull-secrets-gktm99gdtd|regcred|g' base.yaml


# kubectl create secret generic regcred \
#     --from-file=.dockerconfigjson=/home/cloud-user/.docker/config.json> \
#     --type=kubernetes.io/dockerconfigjson
#     # https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#log-in-to-docker

grep -ir IMAGE_REGISTRY *
grep -ir  image\: base.yaml

 #docker login cr.sas.com -u p--3MRwrq7_j5B -p vp1M1Ixc3G_zDKBvcCJKkpvkhSF1Q7kb2nLOKIJW

 kubectl -n viya4ext create secret docker-registry regcred \
 --docker-server=cr.sas.com \
  --docker-username=$(cat /opt/raceutils/.token_user) \
  --docker-password=$(cat /opt/raceutils/.token_pass) \
  --docker-email=erwan.granger@sas.com



sudo yum install jq -y

kubectl -n viya4ext delete secret cr-access &>/dev/null || true

export CR_SAS_COM_SECRET="$(kubectl -n viya4ext create secret docker-registry cr-access \
                --docker-server=cr.sas.com \
                --docker-username=$(cat /opt/raceutils/.token_user) \
                --docker-password=$(cat /opt/raceutils/.token_pass) --dry-run -o json | jq -r '.data.".dockerconfigjson"')"



echo -n $CR_SAS_COM_SECRET | base64 --decode >  ~/viya4ext/bundles/default/overlays/cr_sas_com_access.json

#  add_k_item 'secretGenerator' \
#  '{
#     "name": "sas-image-pull-secrets",
#     "behavior": "replace",
#     "type": "kubernetes.io/dockerconfigjson",
#     "files":
#     [
#        ".dockerconfigjson=overlays/cr_sas_com_access.json"
#     ]
#  }'


# kubectl -n viya4ext get secret regcred --output=yaml
# ./kustomizer.sh --customer-like

kubectl delete -n viya4ext -f base.yaml



#  kubectl apply -n viya4ext -f base.yaml

exit
# gelregistry.exnet.sas.com:5001/09qh4z/vcmnfnd-240.0.0-x64_redhat_linux_7-docker-testready/sas-cas-administration:1.17.17-20200121.1579622730578
# gelregistry.exnet.sas.com:5001/09qh4z/                                                    sas-cas-administration:1.17.17-20200121.1579622730578


# curl -sk https://gitlab.sas.com/convoy/devops/kustomizations/-/archive/master/kustomizations-master.tar.gz | tar  -xz --strip-components=1


# for namespace termination:
    #   kubectl get namespace viya4 -o json | grep -v kubernetes > tmp.json
    #   nohup kubectl proxy  &
    #   sleep 5
    #   curl -k -H "Content-Type: application/json" -X PUT --data-binary @tmp.json http://localhost:8001/api/v1/namespaces/viya4/finalize

