#!/bin/bash

# run it like this
# bash ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/generate.playpen.sh erwan-granger

# cluster level attributes
clustername=$(kubectl config view -o jsonpath="{.clusters[0].name}")
servername=$(kubectl config view -o jsonpath="{.clusters[0].cluster.server}")
echo "Your Cluster is called $clustername"
#echo $servername

if  [ "$1" == "" ]; then
    printf "\nYou need to provide your name like 'firstname-lastname'\n\nExiting\n"
    exit
fi

playpen_name=$1

echo "You want to create a playpen for $playpen_name"
pause(){
 read -n1 -rsp $'Press any key to continue (or Ctrl+C to exit)...\n'
}
#pause

# groupid for student accounts
groupid=1000
# life's easier if the student it part of cloud-user group
# ansible localhost -b -m group -a "name=cloud-user gid=$groupid state=present"


mkdir -p ~/playpens
mkdir -p ~/playpens/kubeconfig


# Create a Resource Quota which will be applied to the new namespaces
tee  ~/playpens/resourcequota.yml > /dev/null << EOF
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-resources
spec:
  hard:
    requests.cpu: "3"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 70Gi

EOF


## if playpen (user already exists, abort)
prevuid=$(cat /etc/passwd | grep ${playpen_name} | awk -F: '{print $3}')
# echo $prevuid
maxuid=$(cat /etc/passwd | awk -F: '{print $3,$1}' | grep -E '^5[0-9]{4}' | sort -n | tail -n 1 | awk  '{print $1}')
# echo $maxuid

if  [ "$prevuid" != "" ]; then
    uid="$prevuid"
else
    if  [ "$maxuid" == "" ]; then
        uid="50001"
    else
        uid=$((maxuid+1))
    fi
fi

echo $uid


# create each user and set the password
student=${playpen_name}
uidvar=${uid}
gidvar=${groupid}

echo "creating user based on playpen name"
pass=$(ansible  localhost -m debug -a "msg={{ 'lnxsas' | password_hash('sha512', 'mysecretsalt') }}" | grep msg | awk -F \" '{print $4}' )
ansible localhost -m user  -a "name=${student} group=cloud-user state=present uid=${uid} password=${pass}" -b --diff



namespace=${student}-ns
contextname=$student@$clustername@$namespace

# create namepace per user and service account in namespace
tee ~/playpens/${student}-ns.yml > /dev/null << EOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: ${namespace}
  labels:
    name: "${namespace}"
EOF

kubectl apply  -f ~/playpens/${student}-ns.yml

## Create serviceaccount.
tee ~/playpens/${student}-sa.yml > /dev/null << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${student}
EOF

kubectl -n $namespace apply  -f ~/playpens/${student}-sa.yml


# get token for user and certificate for cluster
token=$(kubectl -n $namespace describe secrets "$(kubectl -n $namespace describe serviceaccount $student | grep -i Tokens | awk '{print $2}')" | grep token: | awk '{print $2}')
# echo $token
tokenName=$(kubectl -n $namespace describe serviceaccount $student | grep -i Tokens | awk '{print $2}')
# echo $tokenName
certificate=$(kubectl -n $namespace get secret $tokenName  -o "jsonpath={.data['ca\.crt']}")
# echo $certificate


# create kubeconfig file per user
tee ~/playpens/${student}-config.yml > /dev/null << EOF
---
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

tee ~/playpens/${student}-role-rw.yml > /dev/null << EOF
---
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

tee ~/playpens/${student}-rolebinding-rw.yml  > /dev/null << EOF
---
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

kubectl apply -f ~/playpens/${student}-role-rw.yml
kubectl apply -f ~/playpens/${student}-rolebinding-rw.yml

kubectl apply -n $namespace -f  ~/playpens/resourcequota.yml




# distribute the kubeconfig files
ansible localhost -m file -b -a \
"dest=/home/${student}/.kube state=directory owner=${student} group=cloud-user mode=0700"

ansible sasnode01  \
    -b -m copy \
    -a "src=/home/cloud-user/playpens/${student}-config.yml \
        dest=/home/${student}/.kube/config \
        owner=${student} group=cloud-user mode=0600 \
        " \
    --diff

## Enable bash-completion for the new user:
ansible localhost \
    -m lineinfile \
    -b --become-user ${student} \
    -a "dest=~/.bashrc \
        line='source <(kubectl completion bash)' \
        state=present" \
    --diff


printf "\n--------------------------------------------------------------\n"
printf "Your playpen is now ready. \nHere is what you need to do now: \n"
printf "Copy a project from Cloud-user to your new '${student}' account: \n"
printf "sudo chmod 0750 /home/cloud-user \n"
printf " - Log out of sasnode01 (as cloud-user) \n"
printf " - Log back in to sasnode01 as user '${student}' with password 'lnxsas' \n"
printf "           sudo su - ${student} \n"
printf " mkdir -p /home/${student}/project/deploy/${student} \n"
printf " cp -rp /home/cloud-user/project/deploy/functional/* /home/${student}/project/deploy/${student}/ \n"
