#!/bin/bash


# docker image tag byo:v2 gelregistry.exnet.sas.com:5001/09qbt4/byo:v2
# docker image push gelregistry.exnet.sas.com:5001/09qbt4/byo:v2


#Pull image from gelreg
#push to other reg
# get manifests
# deploy.

IMAGE_NAME=gelregistry.exnet.sas.com:5001/09qbt4/byo:v3
NAMESPACE_NAME=posi01

# docker image pull ${IMAGE_NAME}

if kubectl get ns | grep -q ${NAMESPACE_NAME}
then
    echo "found posi01 namespace. deleting it";
    # kubectl delete ns ${NAMESPACE_NAME}
else
    echo "posi01 does not yet exist. ";
fi


mkdir -p ~/${NAMESPACE_NAME} && cd ~/${NAMESPACE_NAME}/


tee ~/${NAMESPACE_NAME}/${NAMESPACE_NAME}-namespace.yml > /dev/null << EOF
apiVersion: v1
kind: Namespace
metadata:
    name: ${NAMESPACE_NAME}
    labels:
    name: "${NAMESPACE_NAME}"
EOF

kubectl apply -f  ~/${NAMESPACE_NAME}/${NAMESPACE_NAME}-namespace.yml


kubectl get ns

tee ~/${NAMESPACE_NAME}/${NAMESPACE_NAME}-configmap.yml > /dev/null << EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: posi01-config
data:
  posi01.RUN_MODE: "developer"
  posi01.DEPLOYMENT_NAME: "erwan_test"
  posi01.CASKEY: "unique-key"
  posi01.SAS_DEBUG: "0"
  posi01.SETINIT_TEXT: |
    PROC SETINIT RELEASE='V03';
     SITEINFO NAME='Viya 3.4 on Containers - small order - 19w25'
     SITE=70180938 OSNAME='LIN X64' RECREATE WARN=45 GRACE=45
     BIRTHDAY='19JUN2019'D  EXPIRE='26JUN2020'D PASSWORD=850027522;
     CPU MODEL=' ' MODNUM=' ' SERIAL=' ' NAME=CPU000;
     CPU MODEL=' ' MODNUM=' ' SERIAL='+9999' NAME=CPU001;
     CPU MODEL=' ' MODNUM=' ' SERIAL='+9999' NAME=CPU002;
     EXPIRE 'PRODNUM000' '26JUN2020'D / CPU=CPU000 CPU001
     CPU002;
     EXPIRE 'PRODNUM001' 'PRODNUM002' 'PRODNUM050' 'PRODNUM094'
     'PRODNUM538' 'PRODNUM564' 'PRODNUM677' 'PRODNUM686'
     'PRODNUM826' 'PRODNUM827' 'PRODNUM921' 'PRODNUM952'
     'PRODNUM985' 'PRODNUM1000' 'PRODNUM1008' 'PRODNUM1009'
     'PRODNUM1010' 'PRODNUM1011' 'PRODNUM1014' 'PRODNUM1055'
     'PRODNUM1200' 'PRODNUM1211' 'PRODNUM1213' 'PRODNUM1228'
     'PRODNUM1231' 'PRODNUM1238' '26JUN2020'D / CPU=CPU000;
     EXPIRE 'PRODNUM1141' '26JUN2020'D / CPU=CPU001;
     EXPIRE 'PRODNUM1100' 'PRODNUM1101' 'PRODNUM1103' 'PRODNUM1104'
     'PRODNUM1106' 'PRODNUM1107' 'PRODNUM1108' 'PRODNUM1109'
     'PRODNUM1110' 'PRODNUM1111' 'PRODNUM1112' 'PRODNUM1113'
     'PRODNUM1115' 'PRODNUM1116' 'PRODNUM1117' 'PRODNUM1119'
     'PRODNUM1120' 'PRODNUM1123' 'PRODNUM1125' 'PRODNUM1127'
     'PRODNUM1128' 'PRODNUM1129' 'PRODNUM1131' 'PRODNUM1133'
     'PRODNUM1135' 'PRODNUM1136' 'PRODNUM1138' 'PRODNUM1140'
     'PRODNUM1142' 'PRODNUM1143' 'PRODNUM1145' 'PRODNUM1146'
     'PRODNUM1148' 'PRODNUM1155' 'PRODNUM1156' 'PRODNUM1158'
     'PRODNUM1159' 'PRODNUM1161' 'PRODNUM1162' 'PRODNUM1163'
     'PRODNUM1165' 'PRODNUM1166' 'PRODNUM1167' 'PRODNUM1168'
     'PRODNUM1181' 'PRODNUM1182' 'PRODNUM1183' 'PRODNUM1184'
     'PRODNUM1186' 'PRODNUM1187' 'PRODNUM1192' 'PRODNUM1194'
     'PRODNUM1195' 'PRODNUM1196' 'PRODNUM1197' 'PRODNUM1198'
     'PRODNUM1500' 'PRODNUM1518' 'PRODNUM1519' 'PRODNUM1520'
     'PRODNUM1521' 'PRODNUM1522' 'PRODNUM1525' 'PRODNUM1526'
     'PRODNUM1527' 'PRODNUM1528' 'PRODNUM1529' 'PRODNUM1537'
     'PRODNUM1538' 'PRODNUM1539' 'PRODNUM1540' 'PRODNUM1541'
     '26JUN2020'D / CPU=CPU002;
     SAVE; RUN;
  posi01.PRE_DEPLOY_SCRIPT: ""
  posi01.POST_DEPLOY_SCRIPT: ""
  posi01.CASENV_CAS_VIRTUAL_HOST: "link_to_CAS_monitor"
  posi01.CASENV_CAS_VIRTUAL_PORT: "80"
EOF



kubectl -n ${NAMESPACE_NAME} apply -f ~/${NAMESPACE_NAME}/${NAMESPACE_NAME}-configmap.yml


kubectl get configmaps -n ${NAMESPACE_NAME}



tee ~/${NAMESPACE_NAME}/${NAMESPACE_NAME}-service.yml > /dev/null << EOF
---
apiVersion: v1
kind: Service
metadata:
  name: sas-programming
  annotations:
    # traefik.backend.loadbalancer.sticky: "true"
    traefik.ingress.kubernetes.io/affinity: "true"
spec:
  selector:
    app: sas-programming
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  - name: cas
    port: 5570
    protocol: TCP
    targetPort: 5570
  #sessionAffinity: None
  sessionAffinity: ClientIP
  clusterIP: None
EOF

kubectl -n ${NAMESPACE_NAME} apply -f  ~/${NAMESPACE_NAME}/${NAMESPACE_NAME}-service.yml

kubectl get services -n ${NAMESPACE_NAME}


tee ~/${NAMESPACE_NAME}/${NAMESPACE_NAME}-deployment.yml > /dev/null << EOF
---
apiVersion: apps/v1
# apiVersion: apps/v1beta1
kind: Deployment
metadata:
  name: sas-programming
spec:
  selector:
    matchLabels:
      app: sas-programming
  replicas: 1
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  template:
    metadata:
      labels:
        app: sas-programming
    spec:
      hostname: sas-programming
      containers:
      - name: sas-programming
        image: $IMAGE_NAME
        imagePullPolicy: Always
        ports:
        - containerPort: 5570
        - containerPort: 80
        env:
        - name: SERVICE_NAME
          value: cascontroller
        - name: CASCFG_MODE
          value: "smp"
        - name: SAS_DEBUG
          valueFrom:
            configMapKeyRef:
              name: posi01-config
              key: posi01.SAS_DEBUG
        - name: RUN_MODE
          valueFrom:
            configMapKeyRef:
              name: posi01-config
              key: posi01.RUN_MODE
        - name: DEPLOYMENT_NAME
          valueFrom:
            configMapKeyRef:
              name: posi01-config
              key: posi01.DEPLOYMENT_NAME
        - name: CASKEY
          valueFrom:
            configMapKeyRef:
              name: posi01-config
              key: posi01.CASKEY
        - name: SETINIT_TEXT
          valueFrom:
            configMapKeyRef:
              name: posi01-config
              key: posi01.SETINIT_TEXT
        - name: PRE_DEPLOY_SCRIPT
          valueFrom:
            configMapKeyRef:
              name: posi01-config
              key: posi01.PRE_DEPLOY_SCRIPT
        - name: POST_DEPLOY_SCRIPT
          valueFrom:
            configMapKeyRef:
              name: posi01-config
              key: posi01.POST_DEPLOY_SCRIPT
        - name: DEMO_USER
          value: "sasdemo"
        - name: DEMO_USER_PASSWD
          value: "lnxsas"
        - name: CASENV_ADMIN_USER
          value: "casadmin"
        - name: ADMIN_USER_PASSWD
          value: "lnxsas"
        - name: CASENV_CASDATADIR
          value: "/cas/data"
        - name: CASENV_CASPERMSTORE
          value: "/cas/permstore"
        resources:
          limits:
            cpu: .1
            memory: 1Gi
          requests:
            cpu: .1
            memory: 1Gi
        volumeMounts:
        - name: cas-volume
          mountPath: /cas/data
        - name: cas-volume
          mountPath: /cas/permstore
        - name: cas-volume
          mountPath: /cas/cache
        - name: data-volume
          mountPath: /data
        - name: sasinside
          mountPath: /sasinside
      volumes:
      - name: cas-volume
        emptyDir: {}
      - name: data-volume
        emptyDir: {}
      - name: sasinside
        emptyDir: {}
EOF

kubectl -n ${NAMESPACE_NAME} apply -f ~/${NAMESPACE_NAME}/${NAMESPACE_NAME}-deployment.yml

kubectl -n ${NAMESPACE_NAME} get deployments

kubectl -n ${NAMESPACE_NAME} get pods

kubectl -n ${NAMESPACE_NAME} get all


kubectl -n ${NAMESPACE_NAME} describe pod

# kubectl --namespace ${NAMESPACE_NAME} port-forward --address 0.0.0.0  svc/sas-programming 1080:80 &


# 1. u=sasdemo
# 1. p=sasdemo

source <( cat /opt/raceutils/.id.txt  )
INGRESS_ALIAS=$long_race_hostname
echo $INGRESS_ALIAS

tee ~/${NAMESPACE_NAME}/${NAMESPACE_NAME}-ingress.yml > /dev/null << EOF
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: ${NAMESPACE_NAME}-ingress
  namespace: ${NAMESPACE_NAME}
  annotations:
    kubernetes.io/ingress.class: traefik
    #traefik.frontend.rule.type: PathPrefixStrip
    #traefik.ingress.kubernetes.io/rewrite-target: /demo
spec:
  rules:
  - host: $INGRESS_ALIAS
    http:
      paths:
      - backend:
          serviceName: sas-programming
          servicePort: 80
EOF


kubectl apply -f ~/${NAMESPACE_NAME}/${NAMESPACE_NAME}-ingress.yml


kubectl get ing --namespace=${NAMESPACE_NAME}

kubectl -n posi01 logs sas-programming-5f5cd6d6d-rvc4w  | grep Password=
