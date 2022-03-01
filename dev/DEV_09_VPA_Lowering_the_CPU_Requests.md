![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Vertical Pod Autoscaler to Lower CPU Requests

* [Codename: VPA](#codename-vpa)
* [Steps](#steps)
  * [Set default namespace to Lab](#set-default-namespace-to-lab)
  * [Cleaning for a failed attempt](#cleaning-for-a-failed-attempt)
  * [Install and Configure VPA](#install-and-configure-vpa)
  * [Create VPA file](#create-vpa-file)
* [reset default namespace](#reset-default-namespace)
* [Back to the main README](#back-to-the-main-readme)

## Codename: VPA

Vertical Pod Autoscaler (VPA) frees the users from necessity of setting up-to-date resource limits and requests for the containers in their pods.

When configured, it will set the requests automatically based on usage and thus allow proper scheduling onto nodes so that appropriate resource amount is available for each pod.

It will also maintain ratios between limits and requests that were specified in initial containers configuration.

It can both down-scale pods that are over-requesting resources, and also up-scale pods that are under-requesting resources based on their usage over time.

For more info, consult [this page](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler#intro)

## Steps

1. Assumption of this exercise is that Viya has been deployed.
1. We will use "Amoeba" deployment for this exercise.
1. We will install and configure "VPA".
1. We will create SAS VPA policy file.
1. We will then apply that file to current Viya deployment.
1. We will then check VPA recommendations
1. We will then "bounce" Viya pods so recommendations are applied

### Set default namespace to Lab

1. Apply it:

    ```bash
    kubectl config set-context --current --namespace=lab
    ```

### Cleaning for a failed attempt

If you need to re-run through this exercise and want to make sure that old content is not causing issues, you'd have to clean things up.
The following steps will only work if you go over all this a second time. Skip them the first time around.

1. Shutdown autoscaler

    ```bash
    ~/project/deploy/autoscaler/vertical-pod-autoscaler/hack/vpa-down.sh
    ```

2. Delete autoscaler directory

    ```bash
    rm -rf ~/project/deploy/autoscaler
    ```

<!--
Irelevant
    ```bash
    cd ~/project/deploy/lab
    sed -i '/SAS VPA/,2d' kustomization.yaml
    ```
-->

1. Delete sas-vpa.yaml

    ```bash
    rm -rf ~/project/deploy/lab/site-config/sas-vpa.yaml
    ```

1. Scale deployments down

    ```bash
    kubectl get deploy -o name | xargs -I % kubectl scale % --replicas=0 -n lab
    ```

1. Scale deployments up again

    ```bash
    kubectl get deploy -o name | xargs -I % kubectl scale % --replicas=1 -n lab
    ```

1. Check that example deployment is back to original values

    ```bash
    kubectl get pod -o=custom-columns=NAME:.metadata.name,PHASE:.status.phase,CPU-REQUEST:.spec.containers\[0\].resources.requests.cpu | grep launcher
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    launcher-87f974b67-2g5lp                         Running     **250m**
    ```

    </details>

### Install and Configure VPA

1. Git clone VPA

    ```bash
    cd ~/project/deploy/
    git clone https://github.com/kubernetes/autoscaler.git
    ```

1. Empty config files

    ```bash
    > ~/project/deploy/autoscaler/vertical-pod-autoscaler/deploy/recommender-deployment.yaml
    > ~/project/deploy/autoscaler/vertical-pod-autoscaler/deploy/updater-deployment.yaml
    ```

1. Populate recommender with new args

```bash
tee  ~/project/deploy/autoscaler/vertical-pod-autoscaler/deploy/recommender-deployment.yaml > /dev/null << "EOF"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vpa-recommender
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vpa-recommender
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vpa-recommender
  template:
    metadata:
      labels:
        app: vpa-recommender
    spec:
      serviceAccountName: vpa-recommender
      containers:
      - name: recommender
        image: us.gcr.io/k8s-artifacts-prod/autoscaling/vpa-recommender:0.8.0
        imagePullPolicy: Always
        command: [./recommender]
        args:
        - --v=4
        - --stderrthreshold=info
        - --pod-recommendation-min-cpu-millicores=10
        - --pod-recommendation-min-memory-mb=100
        - --memory-saver=true
        - --recommender-interval=5m0s
#        - --storage=prometheus
#        - --prometheus-address=http://prometheus-prometheus-oper-prometheus.monitoring.svc.cluster.local:9090
        resources:
          limits:
            cpu: 200m
            memory: 1000Mi
          requests:
            cpu: 50m
            memory: 500Mi
        ports:
        - containerPort: 8080
EOF
```

1. Populate updater with new args

```bash
tee  ~/project/deploy/autoscaler/vertical-pod-autoscaler/deploy/updater-deployment.yaml  > /dev/null << "EOF"
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vpa-updater
  namespace: kube-system
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vpa-updater
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vpa-updater
  template:
    metadata:
      labels:
        app: vpa-updater
    spec:
      serviceAccountName: vpa-updater
      containers:
        - name: updater
          image: us.gcr.io/k8s-artifacts-prod/autoscaling/vpa-updater:0.8.0
          imagePullPolicy: Always
          command: [./updater]
          args:
          - --v=4
          - --stderrthreshold=info
          - --min-replicas=1
          resources:
            limits:
              cpu: 200m
              memory: 1000Mi
            requests:
              cpu: 50m
              memory: 500Mi
          ports:
            - containerPort: 8080
EOF
```

1. Start VPA

    ```bash
    ~/project/deploy/autoscaler/vertical-pod-autoscaler/hack/vpa-up.sh
    ```

1. Check if all system components are running

    ```bash
    kubectl -n kube-system get pods | grep vpa
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    vpa-admission-controller-7f47476b47-7zpjt   1/1     Running     0          66s
    vpa-recommender-654ddbd47b-bkklz            1/1     Running     0          66s
    vpa-updater-6cd84c884-gtdbw                 1/1     Running     0          67s
    ```

    </details>

1. Check that webhook service exists

    ```bash
    kubectl describe -n kube-system service vpa-webhook
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    Name:              vpa-webhook
    Namespace:         kube-system
    Labels:            <none>
    Annotations:       <none>
    Selector:          app=vpa-admission-controller
    Type:              ClusterIP
    IP:                10.43.248.29
    Port:              <unset>  443/TCP
    TargetPort:        8000/TCP
    Endpoints:         10.42.4.251:8000
    Session Affinity:  None
    Events:            <none>
    ```

    </details>

### Create VPA file

1. Populate sas-vpa.yaml

<!--
```bash
vim ~/project/deploy/lab/site-config/sas-vpa.yaml
```
-->

```bash
tee  ~/project/deploy/lab/site-config/sas-vpa.yaml  > /dev/null << "EOF"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: aaservicesls-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: aaservices
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: aaservices2-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: aaservices2
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: annotations-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: annotations
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: appregistry-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: appregistry
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: arke-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: arke
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: audit-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: audit
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: authorization-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: authorization
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: cachelocator-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: cachelocator
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: cacheserver-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: cacheserver
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: cas-control-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: cas-control
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: casadministration-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: casadministration
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: casoperator-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: casoperator
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: comments-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: comments
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: compsrv-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: compsrv
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: compute-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: compute
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: configuration-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: configuration
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: consul-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: consul
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: credentials-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: credentials
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: crossdomainproxy-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: crossdomainproxy
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: dataflows-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: dataflows
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: datamining-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: datamining
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: dataminingprojectsettings-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: dataminingprojectsettings
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: dataminingresults-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: dataminingresults
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: dataplans-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: dataplans
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: dataprofiles-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: dataprofiles
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: devicemanagement-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: devicemanagement
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: files-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: files
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: folders-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: folders
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: fonts-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: fonts
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: geo-enrichment-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: geo-enrichment
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: graphtemplates-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: graphtemplates
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: htmlcommons-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: htmlcommons
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: folders-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: folders
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: identities-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: identities
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: import9-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: import9
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: jobexecution-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: jobexecution
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: launcher-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: launcher
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: lineage-app-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: lineage-app
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: links-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: links
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: localization-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: localization
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: folders-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: folders
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: mail-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: mail
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: maps-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: maps
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: folders-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: folders
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: modelpublish-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: modelpublish
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: modelrepository-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: modelrepository
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: monitoring-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: monitoring
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: naturallanguageconversations-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: naturallanguageconversations
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: naturallanguagegeneration-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: naturallanguagegeneration
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: naturallanguageunderstanding-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: naturallanguageunderstanding
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: notifications-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: notifications
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: postgres-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: postgres
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: postgres-operator-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: postgres-operator
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: preferences-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: preferences
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: projects-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: projects
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: rabbitmq-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: rabbitmq
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: relationships-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: relationships
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: naturallanguageconversations-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: naturallanguageconversations
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: reportdistribution-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: reportdistribution
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: reportexecution-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: reportexecution
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: reportrenderer-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: reportrenderer
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: reportservicesgroup-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: reportservicesgroup
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sas-connect-spawner-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sas-connect-spawner
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sas-data-sources-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sas-data-sources
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sas-grid-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sas-grid
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sas-visual-pipeline-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sas-visual-pipeline
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasdataexplorer-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasdataexplorer
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasdatastudio-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasdatastudio
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasdatasvrut-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasdatasvrut
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasdrive-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasdrive
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasenvironmentmanager-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasenvironmentmanager
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasgraphbuilder-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasgraphbuilder
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasjobexecution-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasjobexecution
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: saslogon-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: saslogon
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasnaturallanguagestudio-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasnaturallanguagestudio
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasstudiov-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasstudiov
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasthemedesigner-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasthemedesigner
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sastransformations-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sastransformations
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: sasvisualanalytics-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: sasvisualanalytics
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: scheduler-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: scheduler
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: scoredefinitions-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: scoredefinitions
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: scoreexecution-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: scoreexecution
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: searchservice-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: searchservice
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: templates-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: templates
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: themecontent-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: themecontent
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: themes-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: themes
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: thumbnails-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: thumbnails
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: transfer-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: transfer
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: types-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: types
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: visualanalyticsadministration-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: visualanalyticsadministration
  updatePolicy:
    updateMode: "Auto"
---
apiVersion: autoscaling.k8s.io/v1beta2
kind: VerticalPodAutoscaler
metadata:
  name: web-data-access-vpa
spec:
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: web-data-access
  updatePolicy:
    updateMode: "Auto"
EOF
```

1. Apply Viya VPA configuration

    ```bash
    cd ~/project/deploy/lab/
    kubectl apply -f site-config/sas-vpa.yaml
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    verticalpodautoscaler.autoscaling.k8s.io/aaservicesls-vpa created
    verticalpodautoscaler.autoscaling.k8s.io/aaservices2-vpa created
    verticalpodautoscaler.autoscaling.k8s.io/annotations-vpa created
    verticalpodautoscaler.autoscaling.k8s.io/appregistry-vpa created
    verticalpodautoscaler.autoscaling.k8s.io/arke-vpa created
    ...
    ```

    </details>

1. Check one pod CPU requests

     ```bash
     kubectl get pod -o=custom-columns=NAME:.metadata.name,PHASE:.status.phase,CPU-REQUEST:.spec.containers\[0\].resources.requests.cpu | grep launcher
     ```

     <details><summary>Click here to see the expected output</summary>

     ```log
     launcher-87f974b67-2g5lp                         Running     250m
     ```

     </details>

1. Check VPA reccomendation for that deployment (wait 5min for first recommendations)

    ```bash
    kubectl describe vpa launcher-vpa
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    Name:         launcher-vpa
    Namespace:    lab
    Labels:       <none>
    Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                    {"apiVersion":"autoscaling.k8s.io/v1beta2","kind":"VerticalPodAutoscaler","metadata":{"annotations":{},"name":"launcher-vpa","namespace":"...
    API Version:  autoscaling.k8s.io/v1beta2
    Kind:         VerticalPodAutoscaler
    Metadata:
    Creation Timestamp:  2020-04-14T20:09:28Z
    Generation:          3
    Resource Version:    170090
    Self Link:           /apis/autoscaling.k8s.io/v1beta2/namespaces/lab/verticalpodautoscalers/launcher-vpa
    UID:                 4b00590b-47c2-4bc0-999a-e574a9ae2312
    Spec:
    Target Ref:
        API Version:  extensions/v1beta1
        Kind:         Deployment
        Name:         launcher
    Update Policy:
        Update Mode:  Auto
    Status:
    Conditions:
        Last Transition Time:  2020-04-14T20:13:18Z
        Status:                True
        Type:                  RecommendationProvided
    Recommendation:
        Container Recommendations:
        Container Name:  launcher
        Lower Bound:
            Cpu:     10m
            Memory:  172989787
        Target:
            Cpu:     11m
            Memory:  511772986
        Uncapped Target:
            Cpu:     11m
            Memory:  511772986
        Upper Bound:
            Cpu:     7931m
            Memory:  368988322906
    Events:          <none>
    ```

    </details>

1. VPA is applied to new pods, therefore lets scale deployments down

    ```bash
    #kubectl get deploy -o name | xargs -I % kubectl scale % --replicas=0 -n lab
    kubectl scale deployments --replicas=0 --all
    ```

1. Scale deployments up again

    ```bash
    #kubectl get deploy -o name | xargs -I % kubectl scale % --replicas=1 -n lab
    kubectl scale deployments --replicas=1 --all
    ```

1. Check the example pod for CPU requests

    ```bash
    kubectl get pod -o=custom-columns=NAME:.metadata.name,PHASE:.status.phase,CPU-REQUEST:.spec.containers\[0\].resources.requests.cpu | grep launcher
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    launcher-87f974b67-nnfmd                         Running     11m
    ```

    </details>

## reset default namespace

1. Make default the default again:

    ```bash
    kubectl config set-context --current --namespace=default
    ```

## Back to the main README

Go back to the [main readme](/README.md)