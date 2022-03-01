#!/bin/bash

while [[ $# -gt 0 ]]; do
    key="$1"
    case ${key} in
        -ri|--reservation-id)
            shift
            RESERVATION_ID="${1}"
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
        --retries)
            shift
            NUMBER_OF_RETRIES="${1}"
            shift
            ;;
        --sleep)
            shift
            SLEEP_BETWEEN_RETRIES="${1}"
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

SLEEP_BETWEEN_RETRIES=${SLEEP_BETWEEN_RETRIES:-30}
NUMBER_OF_RETRIES=${NUMBER_OF_RETRIES:-60}

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

if  [ "${RESERVATION_ID}" == "" ]; then
	printf "\nNo Reservation ID\nExiting\n"
    exit 1
fi

if [[ "$USER_ID" == "" ]] || [[ "$USER_PASS" == "" ]]; then
    echo "one of the params (USER_ID,USER_PASS) seems to be missing"
    exit 1
fi

# Build inventory
 curl -s --user ${USER_ID}:${USER_PASS} -X \
    GET "http://race.exnet.sas.com/api/reservations/${RESERVATION_ID}?AppId=tst" \
    | jq  -c '.serverDetails[] | select(.imageName | contains("LIN_SERVER")) | .serverName ' \
    | sed 's|"||g' | awk '{print $1".race.sas.com"}' \
    | tee inventory.ini


if [ $? -eq 0 ]
then
  echo "Last command seems to have worked! Continuing!"
else
  echo "Last command seems to have had an issue. Stopping with prejudice" >&2
  exit 1
fi

curl -s --user ${USER_ID}:${USER_PASS} -X GET "http://race.exnet.sas.com/api/reservations/${RESERVATION_ID}?AppId=tst" | jq -r '.status'

## Loop until collection is active:

printf '\nWaiting for collection to be active '
for i in $(seq 1 ${NUMBER_OF_RETRIES}); do
    if [ "$(curl -s --user ${USER_ID}:${USER_PASS} -X GET "http://race.exnet.sas.com/api/reservations/${RESERVATION_ID}?AppId=tst" | jq -r '.status')" == "ACTIVE" ] ; then
        printf '\n Collection now Active \n'
       #curl -s --user ${USER_ID}:${USER_PASS} -X GET "http://race.exnet.sas.com/api/reservations/${RESERVATION_ID}?AppId=tst" | jq -r '.status'
       exit 0
    else
        printf '.'
        sleep ${SLEEP_BETWEEN_RETRIES}
        #curl -s --user ${USER_ID}:${USER_PASS} -X GET "http://race.exnet.sas.com/api/reservations/${RESERVATION_ID}?AppId=tst" | jq -r '.status'
    fi

    if [ $i -eq 40 ] ; then
        printf '\n Collection timed out \n'
        exit 1
    fi
done;


