![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

* [doc](#doc)
* [manual steps to do the following:](#manual-steps-to-do-the-following)
  * [Get the operator going](#get-the-operator-going)
  * [fix bug in operator](#fix-bug-in-operator)
  * [build and apply operator](#build-and-apply-operator)
  * [Deploy gelenv-stable-dev through the operator.](#deploy-gelenv-stable-dev-through-the-operator)
* [notes from Darren](#notes-from-darren)
* [from a mirror](#from-a-mirror)
* [getting version diffs](#getting-version-diffs)
* [Automated](#automated)

## doc

Link to doc <http://pubshelpcenter.unx.sas.com:8080/test/?cdcId=itopscdc&cdcVersion=v_004&docsetId=dplyml0phy0dkr&docsetTarget=n0s6wz3kf9kbi4n15ggkuzvvstyu.htm&locale=en>

## manual steps to do the following:

* deploy the SAS Deployment Operator in a Namespace called "robot"
* deploy a copy of the "gelenv-stable" deployment , through the Operator, for 2020.0.3 (call it gelenv-stable-dev )
* deploy a copy of the "gelenv-stable" deployment , through the Operator, for 2020.0.3 (call it gelenv-stabletest )
* update gelenv-stable-dev from 2020.0.4 to 2020.0.6

### Get the operator going

Read inline comments. this will have to be cleaned up

```bash
## to read the readme
cat ~/project/deploy/gelenv-stable/sas-bases/examples/deployment-operator/README.md

## create a working directory:
rm -rf ~/project/deploy/robot
mkdir -p ~/project/deploy/robot

## create a namespace for the SAS Deployment Operator to exist in:
kubectl delete ns robot
kubectl create ns robot

# choose the order we'll use to create the deployment operator  (does not have to match the order you want to deploy)
ORDER=9CDZDD
CADENCE_VERSION=2020.0.6

ORDER_FILE=$(ls ~/orders/ | grep ${ORDER} | grep ${CADENCE_VERSION})
#SASViyaV4_9CDZDD_0_stable_2020.0.4_20200821.1598037827526_deploymentAssets_2020-08-24T165225
echo $ORDER_FILE

## copy that order's .tgz into the robot folder:
cp ~/orders/${ORDER_FILE} ~/project/deploy/robot/
cd  ~/project/deploy/robot/
tar xf *.tgz

## copy the examples in the current folder:
cp -rp ./sas-bases/examples/deployment-operator/deploy/* ./
chmod -R 644 */*.yaml
chmod -R 644 *.yaml
ls -al

## backup the file before we mess with it:
cp ./site-config/transformer.yaml ./site-config/transformer.yaml.orig

## we need to uncomment that second part of the file.
## because we do want to deploy "cluster-wide"
sed -i  's|^#||g' ./site-config/transformer.yaml
# and remove 3 lines of text too:
sed -i '/Transformers\ for\ deployment\ operator/d'  ./site-config/transformer.yaml
sed -i '/Uncomment\ the\ following\ transformers/d'  ./site-config/transformer.yaml
sed -i '/operator\ in\ clusterwide\ mode/d'  ./site-config/transformer.yaml

# replace default namespace with "robot"
sed -i 's|\ default|\ robot|g' ./site-config/transformer.yaml

## review the result:
icdiff ./site-config/transformer.yaml.orig ./site-config/transformer.yaml


cat > /tmp/add_var.yml << EOF
---
- hosts: localhost
  tasks:
  - name: Insert block of YAML into the transformer file
    blockinfile:
      path:  ~/project/deploy/robot/operator-base/transformer.yaml
      insertafter: EOF
      block: |
        ---
        apiVersion: builtin
        kind: PatchTransformer
        metadata:
          name: patch-transformer-sas-deployment-operator-deployment-disable-cleanup
        patch: |-
          - op: add
            path: /spec/template/spec/containers/0/env/-
            value:
              name: DISABLE_CLEANUP
              value: "true"
        target:
          annotationSelector: sas.com/component-name=sas-deployment-operator
          kind: Deployment
EOF

ansible-playbook /tmp/add_var.yml --diff

```

### fix bug in operator

```bash
# replace this file in place:
chmod 664 ~/project/deploy/robot/operator-base/role.yaml
tee ~/project/deploy/robot/operator-base/role.yaml > /dev/null << EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  creationTimestamp: null
  name: sas-deployment-operator
rules:
- apiGroups:
  - orchestration.sas.com
  resources:
  - sasdeployments/finalizers
  verbs:
  - update
- apiGroups:
  - rbac.authorization.k8s.io
  resources:
  - clusterrolebindings
  - clusterroles
  verbs:
  - bind
  - create
  - delete
  - escalate
  - get
  - list
  - patch
  - update
  - watch
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - create
  - delete
  - get
  - list
  - update
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  creationTimestamp: null
  name: sas-deployment-operator
  namespace: DELETEME
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  - events
  - secrets
  verbs:
  - create
  - delete
  - get
  - list
  - update
  - watch
- apiGroups:
  - orchestration.sas.com
  resources:
  - sasdeployments
  verbs:
  - get
  - list
  - update
  - watch
- apiGroups:
  - orchestration.sas.com
  resources:
  - sasdeployments/finalizers
  verbs:
  - update
- apiGroups:
  - rbac.authorization.k8s.io
  resources:
  - rolebindings
  - roles
  verbs:
  - bind
  - create
  - delete
  - escalate
  - get
  - list
  - patch
  - update
  - watch
EOF
```

### build and apply operator

```bash
## OK, now we "kustomize build this whole operator.
## use an explicit name:
kustomize build . -o  operator_manifest.yaml

# And now we apply it
kubectl -n robot apply -f operator_manifest.yaml

## the operator is ready and running in a Robot namespace

```

So, wait for the pod in the robot namespace to be running

```bash
kubectl -n robot get pods

```

if you are curious, you can exec into the pod:

```sh

kubectl -n robot exec -it \
    $(kubectl -n robot get pods -o custom-columns='name:metadata.name' --no-headers) \
    -- bash

```

remember to exit:

```sh
exit
```

Now, you want to keep an eye on the log of the operator, so in another session (or tmux, do)

```bash
kubectl -n robot logs -f -l "app.kubernetes.io/name=sas-deployment-operator"

```

at this point, the operator should kinda work, and there should not be any errors in that log.

### Deploy gelenv-stable-dev through the operator.

create namespace:

```bash
kubectl create ns gelenv-stable-dev

```

and working folder:

```bash
rm -rf  ~/project/deploy/gelenv-stable-dev
mkdir -p ~/project/deploy/gelenv-stable-dev
cd ~/project/deploy/gelenv-stable-dev

```

copy the order we want to deploy with:

```bash
cp ~/project/deploy/robot/sas-bases/examples/deployment-operator/samples/* \
   ~/project/deploy/gelenv-stable-dev/

```



```bash
cd ~/project/deploy/gelenv-stable-dev/
cp sample_inline_sasdeployment.yaml sasdeployment.yaml
chmod 640 sasdeployment.yaml

SECRETS_FILE=~/project/deploy/robot/sas-bases/base/secrets.yaml
LICENSE=$(grep SAS_LICENSE ${SECRETS_FILE} | sed  's|\-\ SAS_LICENSE=||g' )


tee ~/project/deploy/gelenv-stable-dev/gelenv-stable-dev_deployment.yaml > /dev/null << EOF
---
apiVersion: orchestration.sas.com/v1alpha1
kind: SASDeployment
metadata:
  name: my-gelenv-stable-dev-deployment
spec:
  #cadenceName: "stable"
  #cadenceVersion: "2020.0.3"
  cadenceName: "fast"
  cadenceVersion: "2020"
  cadenceRelease: ""
  # The following is an example of how to specify inline user content.
  userContent:
    files:
      "kustomization.yaml": |-
        ---
        namespace: gelenv-stable-dev
        resources:
          - sas-bases/base
          - sas-bases/overlays/network/ingress
          - sas-bases/overlays/internal-postgres
          - sas-bases/overlays/crunchydata
          - sas-bases/overlays/cas-mpp
          - sas-bases/overlays/update-checker       # added update checker
        transformers:
          - sas-bases/overlays/required/transformers.yaml
          - sas-bases/overlays/internal-postgres/internal-postgres-transformer.yaml
        configMapGenerator:
          - name: ingress-input
            behavior: merge
            literals:
              - INGRESS_HOST=gelenv-stable-dev.$(hostname -f)
          - name: sas-shared-config
            behavior: merge
            literals:
              - CASCFG_SERVICESBASEURL=http://gelenv-stable-dev.$(hostname -f)
              - SERVICES_BASE_URL=http://gelenv-stable-dev.$(hostname -f)
              - SAS_SERVICES_URL=http://gelenv-stable-dev.$(hostname -f)
              - SAS_URL_SERVICE_TEMPLATE=http://@k8s.service.name@
          - name: sas-consul-config            ## This injects content into consul. You can add, but not replace
            behavior: merge
            files:
              - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml
      "site-config/gelldap-sitedefault.yaml": |-
        ---
        config:
          application:
            sas.identities.providers.ldap.connection:
              host: 'gelldap-service'
              port: '389'
              url: 'ldap://\${sas.identities.providers.ldap.connection.host}:\${sas.identities.providers.ldap.   connection.port}'
              userDN: 'cn=admin,dc=gelldap,dc=com'
              password: 'lnxsas'
              anonymousBind: 'false'
            sas.identities.providers.ldap.group:
              accountId: 'cn'
              baseDN: 'dc=gelldap,dc=com'
              createdDate: 'createTimestamp'
              distinguishedName: 'none'
              member: 'memberUid'
              memberOf: 'none'
              modifiedDate: 'modifyTimestamp'
              objectClass: 'posixGroup'
              objectFilter: '(objectClass=posixGroup)'
              searchFilter: '\${sas.identities.providers.ldap.group.accountId}={0}'
            sas.identities.providers.ldap.user:
              accountId: 'uid'
              baseDN: 'dc=gelldap,dc=com'
              createdDate: 'createTimestamp'
              distinguishedName: 'none'
              memberOf: 'none'
              modifiedDate: 'modifyTimestamp'
              objectClass: 'posixAccount'
              objectFilter: '(objectClass=posixAccount)'
              searchFilter: '\${sas.identities.providers.ldap.user.accountId}={0}'
            sas.identities.providers.ldap:
              primaryGroupMembershipsEnabled: 'true'
            sas.identities:
              administrator: 'sasadm'
            sas.logon.initial:
              user: sasboot
              password: lnxsas
  license:
    secretKeyRef:
      name: deployment-secrets
      key: license
  clientCertificate:
    secretKeyRef:
      name: deployment-secrets
      key: certificate
  caCertificate:
    secretKeyRef:
      name: deployment-secrets
      key: cacertificate
---
apiVersion: v1
kind: Secret
metadata:
  name: deployment-secrets
type: Opaque
stringData:
  license: $LICENSE
  certificate: |-
    -----BEGIN RSA PRIVATE KEY-----
    MIIEpAIBAAKCAQEA6PtExIXdgBE5NEd3sk0J6kbSqcIpYvmlF728YI0JPBWBiLDW
    NTPZyk8hQgFaMMsJ0OCU4J6qE3p1xnZREoiQiGrgParIh5+M7mh0JQG2yf7RdytU
    ITP4mGb+fUGD/P3c5qRRi6EvrL9ichPZNBZhWP8bpErv4um9xqQPlcsiGUcJrC/P
    ssqS+Nt2lQ7tjFaq1jCgZkq4vvK92BwRdhe/teRTMPlLcXBmlpWh8xgNtLpB3hGM
    fn2YRQO04DLHZ9PStHShX7tuRp+Y7t/4rE6VkTxZesPhmxRcrtKwik/SiOusUCyP
    2jEf7eNhFtGZ4U+wrS0cilwFa/hT40jCjyt7owIDAQABAoIBAQC6ODSkHBeKiLm/
    dqxOwNL/BfLWK1JnQQFbc5WBWtmZw9rQhgABcFtRIGSF3IzZWUCUSx3UWB27CfPf
    WKy+cpeL4lkwETTNapL78FN9TNxsoheM9/37uA2oyxH4zggQjF0noQlo4MI5gpPO
    eNzwjD7tIqNWc2tAZPICNxoZ8c5kgmPkiK79kqgTZAtTD8n+54LApwjfzCoVadWu
    1D2fcZHkvjnVrxTwSrSCB52TksgvZcU1bk6R6vzTpG4S1kqsAja8InHkenJQohcr
    HNxykpfX2ld8hOkPMwZZSgi+jJZhTBgTOejj2oosf2W1cu+lkfExyPw2AF5vrVuD
    i5eAMOkJAoGBAPH3/kpEtFzipHfMuRWvhxvXhu0Z4aISw/nxbsVdAY7Ooe5ZgUAr
    S9sRVKMsG8ouFdklTyrRjua6W9DoEPESsD1tZIxVc22f4Qhzs0w9AUcYskbwGqGc
    4owFOBDY7oVGtJ285gmwEfVqjnMSiq3cSMgPwW8LbUZLxJqpZmpm1CM1AoGBAPZ9
    3GZ9GMJYhax7zFXKGv4LCvwlaVGfZMHa48G2SJrBik8zvgil1qQZVPS7wM3H1gtQ
    XmRQPcSLXjqZ7A/rpGIm8ay0y3YO5pmuumpuv+HS706BvsKUgtNYD6jS8WSSEpKz
    bDtztZXeCwB52OiMHiIaXiU5eX0bIVjgtYUTaGZ3AoGAVIMTlAkPHeojG5yrgIGA
    JR9QBvwlLKB1RpUm5VQouSI+uKsWU71Lj0YsU5mSUzlpdCBt2Dy9NqUccIi9chXe
    7HWKyuEFoeJXjMYsd5JPIe/kRJaUFqJfFhy0il3aYT5i0z0o83VFsHv5KQPu3+6y
    lP27x/crwYOxNXu5Q6yKp4kCgYEA5cfyvEAF4rZu9pn5pEfh3c0hkmi1w3dZkDWj
    eCObj1i4vJi5oIooi5Vp0zNryultqeJj/BOpYR2i2/I9U6IR/cXcKWno+cduRPnT
    ogBYNAZVO9RLpkyXoLlI79KlYWGimstULB/zuR/jFbCA+lgUhyoZdY4cqPmvnpDr
    5oBvJIUCgYBuRPHk75tM+yxqMAFnMgyg8aFSXWL5zS4tizAc1ehJgDYo4kXdiqWs
    0Dh+G4p0WI3FefO9ptyyboVr4vw9S1xVyuRz9T6xH7aoPGJeiz+vA0eKIQ4guLou
    IroPAjyXttqTf0HrkPUsbRzuaacbkJr2vxQ0e0lwEdsgafYwG0UkKQ==
    -----END RSA PRIVATE KEY-----
    -----BEGIN CERTIFICATE-----
    MIIDrTCCApWgAwIBAgIIJNqTXRmuC7owDQYJKoZIhvcNAQELBQAwgagxHDAaBgNV
    BAoME1NBUyBJbnN0aXR1dGUsIEluYy4xHDAaBgNVBAsME1JlbGVhc2UgRW5naW5l
    ZXJpbmcxODA2BgNVBAMML0NlcnRpZmljYXRlIEF1dGhvcml0eSBmb3IgQ2xpZW50
    IEF1dGhlbnRpY2F0aW9uMTAwLgYJKoZIhvcNAQkBFiFTb2Z0d2FyZVByb2R1Y3Rp
    b25TeXN0ZW1zQHNhcy5jb20wHhcNMjAwODIzMDAwMDAwWhcNMzAwODI0MDAwMDAw
    WjBBMQswCQYDVQQGEwJVUzEbMBkGA1UEChMSU0FTIEluc3RpdHV0ZSBJbmMuMRUw
    EwYDVQQDEwxzYXMuZG93bmxvYWQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
    AoIBAQDo+0TEhd2AETk0R3eyTQnqRtKpwili+aUXvbxgjQk8FYGIsNY1M9nKTyFC
    AVowywnQ4JTgnqoTenXGdlESiJCIauA9qsiHn4zuaHQlAbbJ/tF3K1QhM/iYZv59
    QYP8/dzmpFGLoS+sv2JyE9k0FmFY/xukSu/i6b3GpA+VyyIZRwmsL8+yypL423aV
    Du2MVqrWMKBmSri+8r3YHBF2F7+15FMw+UtxcGaWlaHzGA20ukHeEYx+fZhFA7Tg
    Msdn09K0dKFfu25Gn5ju3/isTpWRPFl6w+GbFFyu0rCKT9KI66xQLI/aMR/t42EW
    0ZnhT7CtLRyKXAVr+FPjSMKPK3ujAgMBAAGjQTA/MA4GA1UdDwEB/wQEAwIHgDAM
    BgNVHRMBAf8EAjAAMB8GA1UdIwQYMBaAFE/3c5oPytpLpJ7mk9rM0VDRRgE7MA0G
    CSqGSIb3DQEBCwUAA4IBAQAqfrlbQdPk+M+850mmbCeAa6xQrin9cFIgN0PUxMz9
    yoiv4Z4DgI1QP+E7XeShGJicX00EDDL3AYlStdBJGMDHrLKln6LazT3GFkUgeLMs
    HoEyGSM59YFrdEpi32D7aiEHDPvOnP8gbXBVDiqYa6fS3gIpB9jmq+p9qXc+iftt
    TShl8Od7/tj8s7slZF+V83ldpJ/iqZ9gu2PDOKMiG766kQ+LRGX0SlufWU4g+9ls
    ACagPxkW/A3ZHQ2w9XqYSEaxwmzna0aN8bdif6u7vefCy8RuVOFkJ745LnPEsMzT
    qWrVvXy4CotimrZcUFvahF+sSfDSn+bjUG23GR51Ybq9
    -----END CERTIFICATE-----
  cacertificate: |-
    -----BEGIN CERTIFICATE-----
    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
    NiNQhLrdNnInhFySNA==
    -----END CERTIFICATE-----


EOF

#cat ../robot/operator_manifest.yaml | yq -C r - -d '*'  'data.SAS_LICENSE'
#ClientCertificate
#CACertificate




SECRETS_FILE=~/project/deploy/robot/sas-bases/base/secrets.yaml



kubectl apply -f gelenv-stable-dev_deployment.yaml -n gelenv-stable-dev


```

## notes from Darren

```sh
To get a list of available releases for a given order (as defined by the entitlement certificate) you can run

docker run --rm repulpmaster.unx.sas.com/viya-4-x64_oci_linux_2-docker-testready/sas-orchestration:latest \
    diagnose \
    --diagnose-type releases \
    --cert http://spsrest.fyi.sas.com:8081/comsat/orders/09S9BD/view/soe/entitlement-certificates/entitlement_certificate.pem \
    --cacert http://spsrest.fyi.sas.com:8081/comsat/orders/09S9BD/view/soe/ca-certificates/SAS_CA_Certificate.pem \
    -k

To compare any two releases you can run

docker run --rm repulpmaster.unx.sas.com/viya-4-x64_oci_linux_2-docker-testready/sas-orchestration:latest \
    compare \
    --cert http://spsrest.fyi.sas.com:8081/comsat/orders/09S9BD/view/soe/entitlement-certificates/entitlement_certificate.pem \
    --cacert http://spsrest.fyi.sas.com:8081/comsat/orders/09S9BD/view/soe/ca-certificates/SAS_CA_Certificate.pem \
    --cadence-name fast \
    --cadence-version 2020 \
    --cadence-release 20200903.1599160993454 \
    --to-cadence-name fast \
    --to-cadence-version 2020 \
    --to-cadence-release 20200903.1599167310690 \
    -k

To compare to the latest release you can leave off the --to-cadence-release argument. Neither of these commands show up in the output of ‘help’ and are not currently externally documented but they are production.
```

## from a mirror

Deploy the mirror stuff:

```bash
bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/07_031*.sh
bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/07_032*.sh

```

Now that we have everything in the mirror,

```bash
#!/bin/bash

##############
# User Input #
##############

# What I want
CADENCE=stable
VERSION=2020.0.3

# Where to get it
SOURCE="--repository-warehouse http://harbor.$(hostname -f):443/"
# SOURCE="--deployment-data /cwd/metadata/09S1KP/certs.zip"

####################
# Take the updates #
####################
cd /tmp
docker pull harbor.rext03-0061.race.sas.com//viya/viya-4-x64_oci_linux_2-docker/sas-cas-control@sha256:31c75252a03b20b8f12940293e1d0bdd29165a67192b8550d07704c90075f0bc


SECRETS_FILE=~/project/deploy/gelenv-stable/sas-bases/base/secrets.yaml
CA_CERT=$(awk '/CACertificate/{flag=1;next}/END\ CERTIFICATE/{flag=0}flag' ${SECRETS_FILE} | sed 's|^\ \ \ \ ||g')
CLIENT_CERT=$(awk '/ClientCertificate/{flag=1;next}/END\ CERTIFICATE/{flag=0}flag' ${SECRETS_FILE} | sed 's|^\ \ \ \ ||g')


cat ${SECRETS_FILE} | yq -C r - -d '*'  'data.SAS_LICENSE'

sed -n '/^pattern1/,/^pattern2/p;/^pattern2/q'
sed -n  '/^CACertificate/,/^\-\ \|/p;/^CACertificate/q'  sas-bases/base/secrets.yaml

awk '/CACertificate/{flag=1;next}/END\ CERTIFICATE/{flag=0}flag' sas-bases/base/secrets.yaml | sed 's|^\ \ \ \ |g'

REG_HOST=harbor.$(hostname -f)
IMG_REPO="viya/viya-4-x64_oci_linux_2-docker"
IMG_TAG=$(grep SAS_COMPONENT_TAG_sas-orchestration site.yaml | awk '{ print $2 }')
ORCH_IMG=${REG_HOST}/${IMG_REPO}:${IMG_TAG}
echo $ORCH_IMG

docker run --rm -v "$(pwd)"/sas-deployment:/sas-deployment \
    http://harbor.$(hostname -f)/viya/viya-4-x64_oci_linux_2-docker/sas-orchestration
    repulpmaster.unx.sas.com/viya-4-x64_oci_linux_2-docker-testready/sas-orchestration:1.3.0-20200622.1592860345090 \
    build \
    $SOURCE \
    --cadence-name $CADENCE \
    --cadence-version $VERSION \
    --user-content /sas-deployment \
    --manifest-file \
    --output /sas-deployment

```

## getting version diffs


## Automated

<!--
```sh
# create a kustomization.yaml for easy access to secrets
mkdir -p ~/project/deploy/gelenv-stable-dev/secrets
SECRETS_FILE=~/project/deploy/robot/sas-bases/base/secrets.yaml
cp ${SECRETS_FILE} ~/project/deploy/gelenv-stable-dev/secrets/secrets.yaml

# create a kustomization just for the secrets
tee ~/project/deploy/gelenv-stable-dev/kustomization.yaml > /dev/null << EOF
namespace: gelenv-stable-dev
generators:
  - secrets/secrets.yaml
resources:
  - gelenv-stable-dev_deployment.yaml
EOF

cd ~/project/deploy/gelenv-stable-dev/

## build the secrets!
kustomize build -o secrets_manifests.yaml

## apply the secrets
kubectl apply -n gelenv-stable-dev -f secrets_manifests.yaml

## make sure we have them now:
kubectl -n gelenv-stable-dev get secrets

ok. now that the secrets exist in that namespace, we can reference them.

```
-->
