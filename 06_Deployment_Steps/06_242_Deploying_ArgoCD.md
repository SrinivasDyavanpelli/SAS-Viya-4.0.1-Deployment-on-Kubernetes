![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

## ArgoCD

### Documentation

doc: <https://argoproj.github.io/argo-cd/#getting-started>

### Install ArgoCD

1. Create a namespace

    ```bash
    kubectl delete namespace argocd
    kubectl create namespace argocd
    ```

1. Deploy ArgoCD

    ```bash
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```

1. Configure an ingress for it:

    ```bash
    # ingress:

    bash -c "cat << EOF > /tmp/argo_ing.yaml
    ---
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: argocd-server-ingress
      annotations:
        kubernetes.io/ingress.class: nginx
        nginx.ingress.kubernetes.io/force-ssl-redirect: 'true'
        nginx.ingress.kubernetes.io/ssl-passthrough: 'true'
    spec:
      rules:
      - host: argocd.devops.$(hostname -f)
        http:
          paths:
          - backend:
              serviceName: argocd-server
              servicePort: 443
    EOF"

    kubectl apply -n argocd -f /tmp/argo_ing.yaml
    ```

1. wait for Argo to fully come up:

    ```bash
    waitforpods () {
        PODS_NOT_READY=99
        while [ "${PODS_NOT_READY}" != "0" ]
        do
            PODS_NOT_READY=$(kubectl get pods -n $1 --no-headers | grep -v Completed | grep -E -v '1/1|2/2' | wc -l)
            printf "\n\n\nWaiting for these ${PODS_NOT_READY} pods to be Running: \n"
            kubectl get pods -n $1 --no-headers | grep -v Completed | grep -E -v '1/1|2/2'
            sleep 5
        done
        printf "All pods in namespace $1 seem to be ready \n\n\n\n"
    }

    waitforpods argocd
    ```

1. URL and credentials:

    ```bash
    argocd_password=$(kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)

    printf "\n* [ArgoCD URL (HTTP**S**)](http://argocd.devops.$(hostname -f)/ ) (User=admin Password=${argocd_password})\n\n" | tee -a /home/cloud-user/urls.md
    ```

### Add project in gui of ArgoCD

* create application
  * name:

### Install the ArgoCD CLI

```bash
ansible localhost \
    -b --become-user=root \
    -m get_url \
    -a \
        "url=https://github.com/argoproj/argo-cd/releases/download/v1.4.3/argocd-linux-amd64 \
        dest=/usr/local/bin/argocd \
        validate_certs=no \
        force=yes \
        owner=root \
        mode=0755 \
        backup=yes" \
    --diff
```

### Setup project from the Argo CLI

```bash
argocd login --insecure --username admin --password ${argocd_password} argocd.devops.$(hostname -f)

argocd --insecure  cluster add gelcluster --in-cluster

argocd app create viya4lab \
    --repo http://gitlab.devops.$(hostname -f)/joe/viya4deploy.git \
    --path ./lab/ \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace lab

# http://gitlab.devops.pdcesx11138.race.sas.com/canepg/mytest.git

#export ARGOCD_OPTS='--port-forward-namespace argocd'

```

### Create a lab2 project based on lab

```bash

mkdir ./lab2/
cd lab2

bash -c "cat << EOF > kustomization.yaml
---
namespace: lab2
resources:
  - ../lab/        ## get same content as lab

configMapGenerator:
  - name: ingress-input
    behavior: merge
    literals:
      - INGRESS_HOST=lab2.${INGRESS_SUFFIX}
  - name: sas-shared-config
    behavior: merge
    literals:
      #- SAS_URL_SERVICE_TEMPLATE=http://lab2.${INGRESS_SUFFIX}
      - CASCFG_SERVICESBASEURL=http://lab2.${INGRESS_SUFFIX}
      - SERVICES_BASE_URL=http://lab2.${INGRESS_SUFFIX}
      - SAS_SERVICES_URL=http://lab2.${INGRESS_SUFFIX}
EOF"

git add ./lab2/
git commit -m "adding lab2 folder"
git push

```

### Setup project from the Argo CLI

```bash
argocd login --insecure --username admin --password ${argocd_password} argocd.devops.$(hostname -f)

argocd --insecure  cluster add gelcluster --in-cluster

argocd app create lab2 \
    --repo http://gitlab.devops.$(hostname -f)/joe/viya4deploy.git \
    --path ./lab2/ \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace lab2 \
    --sync-policy automated \
    --auto-prune

```


## STOP HERE

### Install the Argo Workflow and its CLI

1. Install argo wokflow

    ```bash

    kubectl delete namespace argo
    kubectl create namespace argo
    kubectl apply -n argo -f https://raw.githubusercontent.com/argoproj/argo/stable/manifests/install.yaml

    ```

1. Install Argo Workflow CLI

    ```bash

    ansible localhost \
        -b --become-user=root \
        -m get_url -a \
            "url=https://github.com/argoproj/argo/releases/download/v2.2.1/argo-linux-amd64 \
            dest=/usr/local/bin/argo  \
            validate_certs=no \
            force=yes \
            owner=root \
            mode=0755 \
            backup=yes" \
        --diff

    ```

1. Configure an ingress for argoworkflow

    ```bash
    # ingress:

    bash -c "cat << EOF > /tmp/argoworkflow_ing.yaml
    ---
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: argoworkflow-server-ingress
      annotations:
        kubernetes.io/ingress.class: nginx
    spec:
      rules:
      - host: argoworkflow.devops.$(hostname -f)
        http:
          paths:
            - backend:
                serviceName: argo-server
                servicePort: 2746
    EOF"

    kubectl apply -n argo -f /tmp/argoworkflow_ing.yaml
    ```

1. URL :

    ```bash
    printf "\n* [Argo Workflow URL (HTTP)](http://argoworkflow.devops.$(hostname -f)/ ) \n\n" | tee -a /home/cloud-user/urls.md
    ```

### JMeter

#### Deploy Jmeter on K8S

started with <https://hub.helm.sh/charts/stable/distributed-jmeter>

```bash
kubectl delete ns jmeter
kubectl create ns jmeter

helm install  jmeter stable/distributed-jmeter --namespace jmeter

kubectl get all -n jmeter


bash -c "cat << EOF > /tmp/jmeter_ing.yaml
---
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: jmeter-server-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: jmeter.devops.$(hostname -f)
    http:
      paths:
      - backend:
          serviceName: jmeter-distributed-jmeter-server
          servicePort: 443
EOF"

kubectl apply -n argocd -f /tmp/argo_ing.yaml



```

### Or selenium?

would it be better.

<https://github.com/helm/charts/tree/master/stable/selenium>


### Or Locust