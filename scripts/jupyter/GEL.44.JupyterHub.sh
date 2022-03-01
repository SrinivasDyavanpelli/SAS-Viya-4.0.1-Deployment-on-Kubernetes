#!/bin/bash
##############################################################################################
#
#  This script will setup a single-user instance of JupyterHub using Helm.  The default
#  Docker image does not install libnuma, so Erwan graciously built a new image which
#  is stored in gelharbor.  We then need to override the default image when deploying
#  JupyterHub which is shown below in the config.yaml. The swat module was added to the
#  image along with libnuma1.  Also, the configuration will start JupyterLab. Related
#  image configuration files can be found here:
#    - https://gitlab.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes/-/tree/master/scripts/jupyter
#
#  Initial instructions here:
#  - https://zero-to-jupyterhub.readthedocs.io/en/latest/setup-jupyterhub/setup-jupyterhub.html
#  - https://zero-to-jupyterhub.readthedocs.io/en/latest/reference/reference.html
##
#  martho  09OCT2020  Original script
#  martho  15OCT2020  Added integration with gelldap and added NodePorts (Thanks Stuart)
#
##############################################################################################

SECURETOKEN=`openssl rand -hex 32`
LDAP_IP=`kubectl --all-namespaces=true get ep -l app=gelldap-service --output="custom-columns=":.subsets[*].addresses[*].ip""|tail -1`
CONFIGPATH=/home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/jupyter

tee ${CONFIGPATH}/config.yaml > /dev/null <<EOF
---
proxy:
  secretToken: "${SECURETOKEN}"
  service:
    type: NodePort
    nodePorts:
      http: 30080
      https: 30443
singleuser:
  image:
    name: gelharbor.race.sas.com/jupyter/k8s-singleuser-sample-libnuma
    tag: 0.9.0
  defaultUrl: "/lab"
  storage:
    type: none
auth:
  type: ldap
  ldap:
    server:
      address: "${LDAP_IP}"
    dn:
      templates:
        - 'uid={username},ou=users,dc=gelldap,dc=com'
EOF

helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

RELEASE=jhub
NAMESPACE=jhub

helm upgrade --cleanup-on-fail \
  --install ${RELEASE} jupyterhub/jupyterhub \
  --namespace ${NAMESPACE} \
  --create-namespace \
  --version=0.9.0 \
  --values ${CONFIGPATH}/config.yaml

##############################################################################################