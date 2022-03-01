#!/bin/bash

# for later:
# kubectl run curl_test --image=radial/busyboxplus:curl -i -tty -rm --generator=run-pod/v1
# kubectl -n functional run curl-test --image=radial/busyboxplus:curl -i --tty --rm --generator=run-pod/v1

## stop, start, bounce
## all
## parts   (--all or --consul --postgres --rabbit --identities --cas )
## path to site.yaml (--manifest)

# kubectl get ingress -o jsonpath='{range .items[*]}{.spec.rules[].http.paths[].path}{"\n"}{end}'  | sort

# /tmp/gel_OKViya4.sh -n lab  --manifest /home/cloud-user/project/deploy/lab/site.yaml --status

OKViya4_VERSION="Alpha 0.004"


function usage() {
    printf "\nOKViya4: (On Kubernetes) Viya
        a utility script to help start, stop, restart, and check Viya 4.0.1 on Kubernetes\n"
    printf "\n        Version: $OKViya4_VERSION\n"

    printf "\n    -h|--help
    -n|--namespace  <namespace>
    --start
    --start-mode <simultaneous/sequential>
    --stop
    --restart
    --check-ing
    --wait
    --wait-success-rate (95)
    --manifest <./site.yaml>
    --verbose
    --version
    -i|--ingress|--ingress-host  <ingress_alias/auto>
    -p|--ingress-port      <ingress_port>
    --wait       (will wait until everything is healthy to finish)
    --health     (will check the endpoint's health)
    -hm|--health-mode  <internal/external>  (either inside the pods, or outside, using the ingress)
    --start-mode  <random/smart>
    --start
    --dnscheck
    --status
    --stop
    --restart
"
}

####### Functions ##########

pause(){
 read -n1 -rsp $'Press any key to continue (or Ctrl+C to exit)...\n'
}

function state() {
  # local msg="$(date -I) $1"
  local msg="$(date '+%Y%m%d-%H%M%S') $1"
  local flag=$2
  if [ "$flag" -eq 0 ]; then
    echo -e "\e[92m OK    \033[0m $msg"
  elif [ "$flag" -eq -1 ]; then
    echo -e "\e[34m LEARN \033[0m $msg"
  elif [ "$flag" -eq 1 ]; then
    echo -e "\e[93m       \033[0m $msg"
  elif [ "$flag" -eq 2 ]; then
    echo -e "\e[93m WAIT  \033[0m $msg"
  else
    echo -e "\e[91m FAIL  \033[0m $msg"
  fi
}

# Parse command arguments and flags
while [[ $# -gt 0 ]]; do
    key="$1"
    case ${key} in
        -h|--help)
            shift
            usage
            exit 0
            ;;
        -v|--version)
            shift
            usage
            exit 0
            ;;
        --dnscheck)
            shift # past argument
            DNSCHECK="yes"
            ;;
        --verbose)
            shift # past argument
            VERBOSE=true
            ;;
        -n|--namespace)
            shift # past argument
            NS="$1"
            shift # past value
            ;;
        -i|--ingress|--ingress-host)
            shift # past argument
            INGRESS_PREFIX="$1"
            shift # past value
            ;;
        -p|--ingress-port)
            shift # past argument
            INGRESS_PREFIX="$1"
            shift # past value
            ;;
        -hm|--health-mode)
            shift # past argument
            ENDPOINT_TEST="$1"
            shift # past value
            ;;
        --health)
            shift # past argument
            HEALTH="yes"
            ;;
        --wait)
            shift # past argument
            WAIT="yes"
            ;;
        --wait-success-rate)
            shift # past argument
            WAIT_SUCCESS_RATE="$1"
            shift # past value
            ;;
        --start-mode)
            shift # past argument
            START_MODE="$1"
            shift # past value
            ;;
        --start)
            shift # past argument
            START="yes"
            ;;
        --learn)
            shift # past argument
            LEARN="yes"
            ;;
        --status)
            shift # past argument
            STATUS="yes"
            ;;
        --manifest)
            shift
            MANIFEST="$1"
            shift
            ;;
        --stop)
            shift # past argument
            STOP="yes"
            ;;
        --check-ing)
            shift # past argument
            CHECK_ING="yes"
            ;;
        --restart)
            shift # past argument
            RESTART="yes"
            ;;
        *)
            usage
            echo -e "\n\nOne or more arguments were not recognized: \n$@"
            echo
            exit 1
            shift
    ;;
    esac
done

MANIFEST=${MANIFEST:-${PWD}/site.yaml}
K8S_POD_FILTER=${K8S_POD_FILTER:--l "sas.com/deployment=sas-viya"}
# echo $K8S_POD_FILTER
START_MODE=${START_MODE:-random}

MANIFEST_CHECK () {
    if [  -f ${MANIFEST} ]; then
        state "The provided  manifest (${MANIFEST}) exists" 0
    else
        state "The provided  manifest (${MANIFEST}) does not exists" 3
        exit 1
    fi
}

# MANIFEST_CHECK

if_learn () {
    if [ "$LEARN" == "yes" ]; then
        state "$1"  -1
        pause
    fi
}

podname () {
    kubectl -n ${NS} get pods | grep "$1" | awk  '{ print $1 }'
}

NS_Check () {
    if [ "${NS}" == "" ]
    then
        state "You need to supply at least a namespace (with -n <namespace_name>)" 3
        state "Exiting" 3
        exit
    else
    if [  $(kubectl get ns | awk '{ print $1 }' | grep -c ${NS}) -ge 1  ]
        then
            state "You provided the namespace \"${NS}\"" 0
            state "That namespace does exist. Continuing...." 0
        else
            state "The namespace provided (\"${NS}\") is not valid" 3
            state "Here is a list of the valid namespaces in your environment:" 3
            kubectl get ns
            state "To see that list of namespaces, execute the following command:      kubectl get ns  " 3
            exit
        fi
    fi
    if_learn "We expect to work in a specific namespace\n to see all namespaces in your environment, execute the following: \n    kubectl get namespaces"
    if_learn "the result will look like: \n$(kubectl get ns)"
}

Wait_for_Endpoint_success () {

local MIN_SUCC_RATE=$1
local SUCC_RATE=0

until [ "$SUCC_RATE" -ge "$MIN_SUCC_RATE" ];
do
  local ENDPOINTS_COUNT=0
  local ENDPOINT_CODE=0
  local ENDPOINT=0
  local ENDPOINT_RESULT=""
  local COUNT_FAIL=0
  local COUNT_SUCC=0
  local COUNTER=0

    # ENDPOINTS_COUNT=$(kubectl -n ${NS}  exec -ti sas-viya-httpproxy-0 --  grep -Eo 'ProxyPass\ \/.*\/\ ' /etc/httpd/conf.d/proxy.conf | awk '{ print $2 }' | sort | uniq | wc -l)
    # ENDPOINTS_COUNT=$(kubectl -n ${NS}  get services --no-headers | sort | uniq | wc -l)
    # state "We found $ENDPOINTS_COUNT distinct Kubernetes services" 0

    # for url in $(kubectl -n ${NS}  exec -ti sas-viya-httpproxy-0 --  grep -Eo 'ProxyPass\ \/.*\/\ ' /etc/httpd/conf.d/proxy.conf | awk '{ print $2 }' | sort | uniq )
    for url in ${ING_LIST[@]};
    do
      # state "kubectl -n ${NS} exec -it sas-viya-httpproxy-0 -- bash -c 'curl -s -o /dev/null -w ''%{http_code}'' sas-viya-httpproxy:8080'${url%$'\r'}' | tr -d '[:space:]''" 2
        COUNTER=$[$COUNTER +1]
        # if [[ "$ENDPOINT_TEST" == "internal" ]] || [[ "$ENDPOINT_TEST" == "" ]]; then
            # ENDPOINT=http://sas-viya-httpproxy:8080${url%$'\r'}commons/health
            # ENDPOINT_CODE=$(kubectl -n ${NS} exec -it sas-viya-httpproxy-0 -- bash -c 'curl -s -o /dev/null -w ''%{http_code}'' '$ENDPOINT' ' | tr -d '[:space:]' )
            # if [[ "$ENDPOINT_CODE" =~ ^(200)$ ]]; then
            #     ENDPOINT_RESULT="Success"
            #     COUNT_SUCC=$[$COUNT_SUCC +1]
            #     state "curling $ENDPOINT returns HTTP code $ENDPOINT_CODE, which is a $ENDPOINT_RESULT" 0
            # else
            #     ENDPOINT_RESULT="Failure"
            #     COUNT_FAIL=$[$COUNT_FAIL +1]
            #     state "curling $ENDPOINT returns HTTP code $ENDPOINT_CODE, which is a $ENDPOINT_RESULT" 3
            # fi
        # elif [[ "$ENDPOINT_TEST" == "external" ]]; then
            ENDPOINT=${url%$'\r'}commons/health
            ENDPOINT_CODE=$(curl -s -o /dev/null -w '%{http_code}' $ENDPOINT  | tr -d '[:space:]' )
            if [[ "$ENDPOINT_CODE" =~ ^(200)$ ]]; then
                ENDPOINT_RESULT="Success"
                COUNT_SUCC=$[$COUNT_SUCC +1]
                state "curling $ENDPOINT returns HTTP code $ENDPOINT_CODE, which is a $ENDPOINT_RESULT" 0
            else
                ENDPOINT_RESULT="Failure"
                COUNT_FAIL=$[$COUNT_FAIL +1]
                state "curling $ENDPOINT returns HTTP code $ENDPOINT_CODE, which is a $ENDPOINT_RESULT" 2
            fi
        # fi
      #URL=http://$INGRESS_PREFIX:4001${url%$'\r'}
      #HTTP_RETURN_CODE=$(curl --connect-timeout 1 -s -o /dev/null -w "%{http_code}" $URL)
      #printf "HTTP Return Code: $HTTP_RETURN_CODE (from running curl -v  $URL ) \n  "
    done

    state "We have checked $COUNTER endpoints. We found $COUNT_SUCC working, and $COUNT_FAIL failing" 0
    SUCC_RATE=$(echo "scale=2 ; $COUNT_SUCC / $COUNTER * 100" | bc | awk '{print int($1+0.5)}' )

    if [ "$SUCC_RATE" -lt "$MIN_SUCC_RATE" ];    then
        state "Success Rate ($SUCC_RATE %) is not high enough:  " 3
        state "Trying again in 10 seconds.  " 3
        sleep 10
    fi
done

if [ "$SUCC_RATE" -gt "$MIN_SUCC_RATE" ];    then
        state "Success Rate ($SUCC_RATE %) is probably good enough. Not looping anymore." 0
fi

}

function scaleto () {
    # deployment or statefulset, then the name, then the number.
    state "Scaling k8s $1 called \"$2\" to $3" 1
    # kubectl -n ${NS} scale $1 $2 --replicas=$3
    # kubectl -n ${NS} scale $1 $2 --replicas=$3 ${K8S_POD_FILTER} > /dev/null
    kubectl -n ${NS} scale $1 $2 --replicas=$3  > /dev/null

}

waitforpod () {

    #state "Waiting for pod $1 to be running" 2
    PODSTATUS=$(kubectl -n ${NS} get pods | grep $1 | awk '{print $3}')
    while [ "$PODSTATUS" != "Running" ]
    do
        sleep 5
        PODSTATUS=$(kubectl -n ${NS} get pods | grep Running | grep $1 | awk '{print $3}')
        state "Waiting for pod $1 to be running" 2
    done
    state "Pod $1 is running" 0
}

function waitforcontainers () {
    for pause in 5 5 5 5 5 10 10 10 10 10 20 20 20 20
    do
        CONTAINERSREADY=$(( $(kubectl -n ${NS} get pods  | grep $1 | awk '{print $2}') ))
        if  [ "$CONTAINERSREADY" -lt "1" ];  then
            state "Waiting for all containers in pod  '$1' to start. So far, $(kubectl -n ${NS} get pods  | grep $1 | awk '{print $2}') are running." 2
            sleep ${pause}
        else
            state "All Containers in pod '$1' are running" 0
            break
        fi
    done
}



curlwaitforhttp () {
    #state "Waiting for endpoint $1 in ${NS} to return an http code of $2." 2
    MYHTTPCODE=$(kubectl -n ${NS} exec -it sas-consul-server-0 -- bash -c 'curl -s -o /dev/null -w ''%{http_code}'' sas-viya-httpproxy:8080'$1' | tr -d '[:space:]'')
    # state "Endpoint $1 returned HTTP code: $MYHTTPCODE" 2
    while [ "$MYHTTPCODE" != "$2" ]
    do
        #echo "Endpoint $1 in ${NS} is not returning code $2. Got code: $MYHTTPCODE"
        state "Endpoint $1 returned HTTP code: $MYHTTPCODE. Was hoping for $2" 2
        state "DEBUG STEP:         kubectl -n ${NS} exec -it sas-viya-httpproxy-0 -- bash -c 'curl -v sas-viya-httpproxy:8080$1' " 2
        sleep 5
        MYHTTPCODE=$(kubectl -n ${NS} exec -it sas-viya-httpproxy-0 -- bash -c 'curl -s -o /dev/null -w ''%{http_code}'' sas-viya-httpproxy:8080'$1' | tr -d '[:space:]'')
        #echo MYHTTPCODE is : $MYHTTPCODE
    done
    state "Endpoint $1 in ${NS} is responding with HTTP $2" 0
}


check_port_inside_pod () {
    # pod, port, good RC:
    #state "Waiting for pod $1 in ${NS} to be listening on port $2. Hoping for RC: $3" 2
    #state "kubectl -n ${NS} exec -it $(podname $1) -- bash -c 'curl -s -q -o /dev/null localhost:'$2'" 1
    MYRC=$(kubectl -n ${NS} exec -it $(podname $1) -- bash -c 'curl -s -q -o /dev/null localhost:'$2' ; res=$? ; echo $res | tr -d '[:space:]'')
    while [ "$MYRC" != "$3" ]
    do
        state "Service $1 in ${NS} is not listening on port $2. Got the return code: $MYRC. Was hoping for $3" 2
        sleep 5
        MYRC=$(kubectl -n ${NS} exec -it $(podname $1) -- bash -c 'curl -s -q -o /dev/null localhost:'$2' ; res=$? ; echo $res | tr -d '[:space:]'')
    done
    state "Success! service $1 in ${NS} is listening on port $2" 0

}

curlwaitforport () {
    # host, port, good RC:
    #state "Waiting for service $1 in ${NS} to be listening on port $2. Hoping for RC: $3" 2
    MYRC=$(kubectl -n ${NS} exec -it sas-viya-httpproxy-0 -- bash -c 'curl -s -q -o /dev/null '$1':'$2' ; res=$? ; echo $res | tr -d '[:space:]'')
    while [ "$MYRC" != "$3" ]
    do
        state "Service $1 in ${NS} is not listening on port $2. Got the return code: $MYRC. Was hoping for $3" 2
        sleep 5
        MYRC=$(kubectl -n ${NS} exec -it sas-viya-httpproxy-0 -- bash -c 'curl -s -q -o /dev/null '$1':'$2' ; res=$? ; echo $res | tr -d '[:space:]'')
    done
    state "Success! service $1 in ${NS} is listening on port $2" 0
}

Find_Ingress_Names () {

    ING_LIST=($(kubectl -n ${NS} get ing \
        -o custom-columns='host:spec.rules[*].host, backendpath:spec.rules[*].http.paths[*].path' \
        --no-headers | \
        sed 's/[(/|$)(*)]//g' | \
         awk  '{  print "http://" $1 "/" $2 "/" }' \
          | sed 's/\.\//\//g' \
          | sed 's/\.\,\//\//g' \
          | sort \
          | uniq \
          ))

    # local ING_COUNT="$(ING_LIST) | wc -l"
    state "Found ${#ING_LIST[@]} distinct Kubernetes Ingresses in namespace ${NS}" 0

    # # to print the ingresses:
    # for I in ${ING_LIST[@]}; do
    #     printf "$I\n"
    # done

    # printf "$ING_LIST"

}


Find_Service_Names () {

    SERVICE_LIST=($(kubectl -n ${NS} get service \
        -o custom-columns='host:metadata.name' \
        --no-headers  \
          | sort \
          | uniq \
          ))

    SERVICE_LIST_HTTP=($(kubectl -n ${NS} get service  --no-headers \
       | grep ' 80/TCP'  \
       |    awk '{ print $1 }' \
          | sort \
          | uniq \
          ))

    state "Found ${#SERVICE_LIST[@]} distinct Kubernetes Services in namespace ${NS}" 0
    state "Found ${#SERVICE_LIST_HTTP[@]} distinct HTTP Kubernetes Services in namespace ${NS}" 0


    # to print the ingresses:
    # for I in ${SERVICE_LIST_HTTP[@]}; do
    #     printf "$I\n"
    # done


}

#######################  End of functions #####################

# MYNS=$1
state "OKViya4 Version: $OKViya4_VERSION " 0

if_learn "Get your LEARN on! \n \
You have enabled the learn mode, which will be a lot slower but a lot more descriptive"

## check that the namespace is provided and accurate
NS_Check

Find_Ingress_Names

Find_Service_Names

function start_deployments () {
    if  [ "$1" == "" ]; then
        PATT="sas-"
    else
        PATT="$1"
    fi
    local DEPLOYMENT_LIST=($(kubectl -n ${NS} get deploy -o NAME | grep -E "${PATT}"))

    for dep in ${DEPLOYMENT_LIST[@]}; do
        dep_status=$(kubectl -n ${NS} get ${dep} )
        ### only scale the deployment up to 1 if it's not available yet
    done


}
#start_deployments

# state "Chosen namespace is : ${NS} " 0

if [[ "$INGRESS_PREFIX" == "" ]] || [[ "$INGRESS_PREFIX" == "auto" ]]; then
    # INGRESS_PREFIX=$(kubectl describe  ing -n ${NS}  | grep insecure | head -n 1 | awk '{print $1}')
    echo
fi
# state "The Ingress hostname is: $INGRESS_PREFIX" 0

if  [[ "$STOP" == "yes" ]]; then
    # state "You have asked for reset to be $RESET" 1
    state "Scaling deployments in the namespace down to zero" 1
    #scaleto deployments --all 0
    scaleto deployments "${K8S_POD_FILTER}" 0
    state "Scaling statefulsets in the namespace down to zero" 1
    scaleto statefulset "${K8S_POD_FILTER}" 0

    state "Stopping CAS by deleting k8s CASDeployment default" 1
    kubectl -n ${NS} delete casdeployment default

    state "Stopping crunchy" 2
    scaleto deployment " -l vendor=crunchydata" 0

fi


if [[ "$START" == "yes" ]] ; then
    if  [[ "$START_MODE" == "random" ]]; then
        state "Applying manifest" 1
        kubectl -n ${NS} apply -f ${MANIFEST} > /dev/null

        state "Scaling up k8s deployments " 1
        scaleto deployments "${K8S_POD_FILTER}" 1
        state "Scaling up k8s statefulsets " 1
        scaleto statefulset "${K8S_POD_FILTER}" 1
    fi

    if [[ "$START_MODE" == "smart" ]]; then
    # if [[ "$START_MODE" == "smart" ]] || [[ "$START_MODE" == "" ]]; then
        scaleto statefulset sas-consul-server 1
        scaleto deployment sas-crunchy-data-postgres-operator 1
        scaleto statefulset sas-rabbitmq-server  1
        scaleto deployment " -l vendor=crunchydata" 1
        scaleto deployment sas-cachelocator 1
        scaleto statefulset sas-cacheserver 1

        waitforpod sas-consul-server
        waitforpod sas-crunchy-data-postgres-operator
        waitforpod sas-rabbitmq-server-0

        waitforcontainers sas-consul-server
        check_port_inside_pod consul 8500 0
        waitforcontainers sas-crunchy-data-postgres-operator
        waitforcontainers sas-rabbitmq-server-0

        waitforpod sas-crunchy-data-postgres-backrest
        waitforcontainers sas-crunchy-data-postgres-backrest

        waitforpod sas-cacheserver-0
        waitforcontainers sas-cacheserver-0
        waitforpod sas-cachelocator-
        waitforcontainers sas-cachelocator-

        scaleto deployment sas-identities 1
        scaleto deployment sas-environment-manager-app 1
        scaleto deployment sas-folders 1
        # scaleto deployment compute 1
        scaleto deployment sas-logon-app 1
        scaleto deployment sas-themes 1
        scaleto deployment sas-theme-content 1
        scaleto deployment sas-app-registry 1
        scaleto deployment sas-arke 1
        scaleto deployment sas-cas-operator 1
        scaleto deployment sas-files 1
        scaleto deployment sas-drive 1
        scaleto deployment sas-fonts 1
        scaleto deployment sas-links 1
        scaleto deployment sas-launcher 1

        # scaleto deployment preferences 1
        # scaleto deployment casoperator 1
        #curlwaitforhttp /SASLogon 302
        #check_port_inside_pod sas-logon-app 80 0


        #waitforpod sas-environment-manager-app
        #waitforcontainers sas-environment-manager-app


        waitforpod sas-logon-app
        waitforpod sas-identities-
        waitforpod sas-drive-app
        # waitforpod folders
        waitforcontainers sas-identities-
        waitforcontainers sas-logon-app
        waitforcontainers sas-drive-app
        # waitforpod preferences
        #waitforpod sas-folders

        scaleto deployment --all 1
        scaleto sts --all 1

        kubectl -n ${NS} apply -f ${MANIFEST} > /dev/null

        # curlwaitforport sas-viya-consul 8500 0

        # curlwaitforport sas-viya-sasdatasvrc 5432 52

        # scaleto statefulset sas-viya-pgpoolc 1
        # waitforpod sas-viya-pgpoolc-0

        # curlwaitforport sas-viya-pgpoolc 5431 52

        # scaleto statefulset sas-viya-rabbitmq 1
        # waitforpod sas-viya-rabbitmq-0

        # curlwaitforport sas-viya-rabbitmq 5672 56

        # scaleto deployment sas-viya-coreservices 1
        # #scaleto deployment sas-viya-homeservices 1

        # scaleto statefulset sas-viya-cas 1
        # scaleto statefulset sas-viya-computeserver 1
        # scaleto statefulset sas-viya-programming 1

        # #showendpoints
        # waitforpod sas-viya-coreservices

        # scaleto deployment sas-viya-adminservices 1
        # scaleto deployment sas-viya-cas-worker 1
        # scaleto deployment sas-viya-casservices 1
        # scaleto deployment sas-viya-cognitivecomputingservices 1
        # scaleto deployment sas-viya-computeservices 1
        # scaleto deployment sas-viya-configuratn 1
        # scaleto deployment sas-viya-dataservices 1
        # scaleto deployment sas-viya-graphbuilderservices 1


        # curlwaitforhttp / 302

        # curlwaitforhttp /cacheserver/commons/health 200
        # curlwaitforhttp /cachelocator/commons/health 200
        # waitforpod sas-viya-homeservices

        # curlwaitforhttp /SASDrive 302

        # curlwaitforhttp /SASLogon 302

        # curlwaitforhttp /SASEnvironmentManager 302

        # curlwaitforhttp /SASStudio 302
        # curlwaitforhttp /SASStudioV 302
        # curlwaitforhttp /authorization 302
        # curlwaitforhttp /SASVisualAnalytics 302
    fi
fi

if [[ "$DNSCHECK" == "yes" ]]; then
	for p in $(kubectl get pods -n ${NS} | grep Running | awk  '{ print $1 }' )
	do
		NODE=$(kubectl -n ${NS} describe pod $p  | grep 'Node\:' | awk '{ print $2 }' )
		#printf "On node $NODE, inside of pod $p, the DNS is ................"
		DNS=$(kubectl -n ${NS} exec  $p -- bash -c ' ping -q -W 1 -c 1 sas-viya-httpproxy &> /dev/null ; echo $? ')
		#kubectl -n ${NS} exec  $p -- bash -c ' ping -q -W 1 -c 1 sas-viya-httpproxy2  ; echo $? '
		if [ "$DNS" -eq 0 ] ; then
			state "On node $NODE, inside of pod $p, the DNS is ................Working" 0
		else
			state "On node $NODE, inside of pod $p, the DNS is ................Failing" 3
		fi
		#kubectl -n ${NS} exec  $p -- bash -c ' cat /etc/resolv.conf '
		#kubectl -n ${NS} exec  $p -- bash -c ' cat /etc/hosts '

	done
fi


if [[ "$STATUS" == "yes" ]] ; then
    READY_PODS=$(kubectl -n ${NS} get pods |  grep Running | grep -E "1/1|2/2|3/3|4/4|5/5|6/6")
    NOT_READY_PODS=$(kubectl -n ${NS} get pods |  grep -v Completed | grep -E "0/")


    READY_PODS_COUNT=$( echo -n "${READY_PODS}" | wc -l )
    NOT_READY_PODS_COUNT=$( echo -n "${NOT_READY_PODS}" | wc -l )
    state "Found ${READY_PODS_COUNT} pods in \"Ready\" state" 0
    state "Found ${NOT_READY_PODS_COUNT} pods in \"Not quite Ready yet\" state" 0



    #state "${READY_PODS}" 0
    ## find the name of the consul pod:
    # CONSUL_POD=$(kubectl -n ${NS} get pods | grep consul | awk  '{ print $1 }' )
    # echo $CONSUL_POD

    # kubectl -n ${NS} logs $(podname consul)
    # kubectl -n ${NS} logs $(podname cachelocator)
    # kubectl -n ${NS} logs $(podname saslogon)


    # kubectl -n viya4 run -it --rm --restart=Never curl --image=curlimages/curl sh
    # kubectl -n viya4 run -it --rm --restart=Never curl --image=curlimages/curl sh -c "curl -m 1 -s -o /dev/null -w '%{http_code}' -kv saslogon:80"


    # kubectl -n ${NS}  exec -ti $CONSUL_POD -- curl -kv consul:8300
    # # show me all the services that are not yet up.
    # state  "Checking status across all pods, matching the string '$STATUS' (this might be slow)" 2
    # for p in $(kubectl get pods -n ${NS} | grep Running | awk  '{ print $1 }' );     do         kubectl -n ${NS} exec  $p -- /etc/init.d/sas-viya-all-services status | sed "s/$/    -------  Pod: $p /" &     done  | grep -E -i "$STATUS"
    # # for p in $(kubectl get pods -n ${NS} | grep Running | awk  '{ print $1 }' );     do         kubectl -n ${NS} exec  $p -- /etc/init.d/sas-viya-all-services status | sed "s/$/    -------  Pod: $p /" &     done
    # for p in $(kubectl get pods -n ${NS} | grep Running | awk  '{ print $1 }' );      do              kubectl -n ${NS} exec  $p -- bash -c 'for s in $(ls /etc/init.d/  | awk "{print $1}" | grep viya | grep -v sas-viya-all-services ) ; do  /etc/init.d/$s status ;done' | sed "s/$/    -------  Pod: $p /" &      done   |  grep -E -i "$STATUS"
fi

#kubectl -n fumi02 exec -it sas-viya-coreservices-7c8496f77f-pjjfj -- bash
#grep "JVM running for" /opt/sas/viya/config/var/log/cache*/default/*.log

if [[ "$WAIT" == "yes" ]] ; then
    echo
    # waitforpod sas-viya-httpproxy-0
    # waitforpod sas-viya-consul-0
    # curlwaitforport sas-viya-httpproxy 8080 0
    # curlwaitforport sas-viya-consul 8500 0
    # waitforpod sas-viya-sasdatasvrc-0
    # curlwaitforport sas-viya-sasdatasvrc 5432 52
    # waitforpod sas-viya-pgpoolc-0
    # curlwaitforport sas-viya-pgpoolc 5431 52
    # waitforpod sas-viya-rabbitmq-0
    # curlwaitforport sas-viya-rabbitmq 5672 56
    # scaleto statefulset sas-viya-cas 1
    # scaleto statefulset sas-viya-computeserver 1
    # scaleto statefulset sas-viya-programming 1
    # waitforpod sas-viya-coreservices
    # curlwaitforhttp /cacheserver/commons/health 200
    # curlwaitforhttp /cachelocator/commons/health 200
    # curlwaitforhttp / 302
    # curlwaitforhttp /cacheserver/commons/health 200
    # curlwaitforhttp /cachelocator/commons/health 200
    # waitforpod sas-viya-homeservices
    # curlwaitforhttp /SASDrive 302
    # curlwaitforhttp /SASLogon 302
    # curlwaitforhttp /SASEnvironmentManager 302
    # curlwaitforhttp /SASStudio 302
    # curlwaitforhttp /SASStudioV 302
    # curlwaitforhttp /authorization 302
    # curlwaitforhttp /SASVisualAnalytics 302
fi

if [[ "$WAIT" == "yes" ]] ; then
    # waitforpod $(podname postgres-operator)
    # check_port_inside_pod consul 8300 56
    # waitforpod $(podname consul)
    # waitforpod $(podname rabbitmq)
    # waitforpod $(podname logon)

    Wait_for_Endpoint_success 90
fi

exit
