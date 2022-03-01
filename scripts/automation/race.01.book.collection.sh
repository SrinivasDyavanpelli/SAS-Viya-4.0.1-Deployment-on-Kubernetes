#!/bin/bash

while [[ $# -gt 0 ]]; do
    key="$1"
    case ${key} in
        -d|--domain)
            shift
            DOMAIN="${1}"
            shift
            ;;
        -u|--user)
            shift
            USER_ID="${1}"
            shift
            ;;
        -p|--pass)
            shift
            USER_PASS="${1}"
            shift
            ;;
        -ci|--coll-id)
            shift
            COLL_ID="${1}"
            shift
            ;;
        -cc|--coll-comment)
            shift
            COLL_COMMENT="${1}"
            shift
            ;;
        -ch|--coll-hours)
            shift
            COLL_HOURS="${1}"
            shift
            ;;
        --additional-emails)
            shift
            ADDITIONAL_EMAILS="${1}"
            shift
            ;;
        *)
            echo -e "\n\nOne or more arguments were not recognized: \n$@"
            echo
            exit 1
            shift
    ;;
    esac
done




## assigning default values
DOMAIN=${DOMAIN:-carynt}
COLL_ID=${COLL_ID:-0}
ADDITIONAL_EMAILS=${ADDITIONAL_EMAILS:-}
COLL_COMMENT=${COLL_COMMENT:-'Default Collection Booking'}
COLL_HOURS=${COLL_HOURS:-6}

# confirm jq is installed
function check_jq(){
    which jq
    if [ $? -ne 0 ]
    then
        echo "Can't seem to find jq. Stopping with prejudice" >&2
        exit 1
    fi
}
check_jq

if [[ "$COLL_ID" == "" ]] || [[ "$USER_ID" == "" ]] || [[ "$USER_PASS" == "" ]]; then
    echo "one of the params (COLL_ID,USER_ID,USER_PASS) seems to be missing"
    exit
fi



# unameOut="$(uname -s)"
# case "${unameOut}" in
#     Linux*)     machine=Linux;;
#     Darwin*)    machine=Mac;;
#     CYGWIN*)    machine=Cygwin;;
#     MINGW*)     machine=MinGw;;
#     *)          machine="UNKNOWN:${unameOut}"
# esac

# RES_START=$(date +%D +%r)
RES_START=$(date "+%D %r")

test="$(uname -s)"
echo ${test}

if [[ "$(uname -s)" == "Linux" ]]; then
    echo "linux"
    RES_END=$(date -d "+${COLL_HOURS} hours"  "+%D %r" )
fi
if [[ "$(uname -s)" == "Darwin" ]] ; then
    echo "mac"
    RES_END=$(date   -v+${COLL_HOURS}H "+%D %r")
fi

echo $RES_START
echo $RES_END


tee  res.json > /dev/null << EOF
{
   "AppId":"tstReservation",
   "scheduleId":"0",
   "scheduleType":"Scheduled",
   "admin":"false",
   "overrideOutage":"false",
   "domain":"CARYNT",
   "userId":"${USER_ID}",
   "startDate":"${RES_START}",
   "endDate":"${RES_END}",
   "imageId":"${COLL_ID}",
   "imageKind":"C",
   "machineStatus":"A",
   "comments":"${COLL_COMMENT}",
   "purpose":"B",
   "numberOfServers":"1",
   "options":"${ADDITIONAL_EMAILS};N;Y;N"
}
EOF

cat res.json | jq

#Then run this command:


BOOKIT=$(curl --user ${USER_ID}:${USER_PASS} -X POST \
   -H "Content-Type: application/json" \
   http://race.exnet.sas.com/api/reservations \
   --data @res.json)


if [ $? -eq 0 ]
then
  echo "Last command seems to have worked! Continuing!"
else
  echo "Last command seems to have had an issue. Stopping with prejudice" >&2
  exit 1
fi


echo ${BOOKIT} | tee res.id.txt


curl --user ${USER_ID}:${USER_PASS} -X GET  \
  http://race.exnet.sas.com/api/reservations/${BOOKIT}?AppId=tst | jq | tee res.details.json

#curl --user ${USER_ID}:${USER_PASS} \
 #    -H "Content-Type: application/json" \
 #   http://race.exnet.sas.com/api/reservations?AppId=tst | jq



#http://perc.na.sas.com/doc/Applications/Wintel/SIMS/RACE_REST_API.htm

# echo "${USER_ID}:${USER_PASS} ${U_N} ${U_P} "

# curl --user ${USER_ID}:${USER_PASS} \
#      -H "Content-Type: application/json" \
#      http://race.exnet.sas.com/api/reservations?AppId=tst | jq


