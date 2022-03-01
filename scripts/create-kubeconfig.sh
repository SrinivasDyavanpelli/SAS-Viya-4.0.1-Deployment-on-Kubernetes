#!/bin/sh

# cluster level attributes
clustername=$(kubectl config view -o jsonpath="{.clusters[0].name}")
servername=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}")
echo $clustername
echo $servername



# groupid for student accounts
groupid=4000

mkdir -p ~/namespace
mkdir -p ~/namespace/kubeconfig

# Create a Resource Quota which will be applied to the new namespaces
tee  ~/namespace/resourcequota.yml > /dev/null << EOF
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi

EOF


sudo groupadd -g $groupid gelstudents


for i in {01..25};
do

# create each user and set the password
student=gelstudent${i}
uidvar=40${i}
gidvar=$groupid

echo Running command: adduser $student -u $uidvar -g $gidvar
sudo adduser $student -u $uidvar -g $gidvar
echo Running command: passwd $student

echo $student
echo "lnxsas" | sudo passwd --stdin "$student"
echo; echo "User $student's password changed"

namespace=${student}ns
contextname=$student@$clustername@$namespace

# create namepace per user and service account in namespace
kubectl create ns $namespace
kubectl -n $namespace create serviceaccount $student

# get token for user and certificate for cluster
token=$(kubectl -n $namespace describe secrets "$(kubectl -n $namespace describe serviceaccount $student | grep -i Tokens | awk '{print $2}')" | grep token: | awk '{print $2}')
echo $token
tokenName=$(kubectl -n $namespace describe serviceaccount $student | grep -i Tokens | awk '{print $2}')
echo $tokenName
certificate=$(kubectl -n $namespace get secret $tokenName  -o "jsonpath={.data['ca\.crt']}")
echo $certificate

# create kubeconfig file per user
tee ~/namespace/kubeconfig/${student}.yml > /dev/null << EOF

apiVersion: v1
kind: Config
preferences: {}

clusters:
- cluster:
    certificate-authority-data: $certificate
    server: $servername
  name: $clustername

contexts:
- context:
    cluster: $clustername
    namespace: $namespace
    user: $student
  name: $contextname

users:
- name: $student
  user:
    as-user-extra: {}
    client-key-data: $certificate
    token: $token

current-context: $contextname

EOF

# create a role which gives the user all permissions for the user based namespace

tee ~/namespace/role_rw_${student}.yml > /dev/null << EOF

kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  namespace: $namespace
  name: $namespace-rw
rules:
- apiGroups: ["", "extensions", "apps"]
  resources: ["*"]
  verbs: ["*"]
- apiGroups: ["batch"]
  resources:
  - jobs
  - cronjobs
  verbs: ["*"]

EOF

# create a role-binding

tee ~/namespace/rolebinding_rw_${student}.yml  > /dev/null << EOF

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name:  $namespace-rw
  namespace: $namespace
subjects:
- kind: ServiceAccount
  name: $student
  namespace: $namespace
roleRef:
  kind: Role
  name: $namespace-rw
  apiGroup: rbac.authorization.k8s.io

EOF

kubectl create -f ~/namespace/role_rw_${student}.yml
kubectl create -f ~/namespace/rolebinding_rw_${student}.yml

kubectl apply -n $namespace -f  ~/namespace/resourcequota.yml

# distribute the kubeconfig files
sudo mkdir -p /home/${student}/.kube
sudo cp ~/namespace/kubeconfig/${student}.yml   /home/${student}/.kube/config

done
