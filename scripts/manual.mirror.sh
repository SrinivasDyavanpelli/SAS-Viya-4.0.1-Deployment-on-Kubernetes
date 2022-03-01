#!/bin/bash

function usage() {
    printf "\n manual.mirror.sh: "

    printf "\n    -h|--help
    -o|--order <order>
    -u|--reg-user <user for registry>
    -p|--reg-pass <password for registry>
    -h|--reg-host <hostname for registry>
    -pa|--prune-all <0/1>
    -d|--delete-on-the-fly (0/1)
"
}

function exit_if_bad(){
  if [ $? -eq 0 ]
  then
    echo "Last command seems to have worked! Continuing!"
  else
    echo "Last command seems to have had an issue. Stopping with prejudice" >&2
    exit 1
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
        -o|--order)
            shift # past argument
            ORDER="$1"
            shift # past value
            ;;
        -cv|--cadence-version)
            shift # past argument
            CADENCE_VERSION="$1"
            shift # past value
            ;;
        -u|--reg-user)
            shift # past argument
            REG_USER="$1"
            shift # past value
            ;;
        -p|--reg-pass)
            shift # past argument
            REG_PASS="$1"
            shift # past value
            ;;
        -d|--delete-on-the-fly)
            shift # past argument
            DELETE_ON_THE_FLY="$1"
            shift # past value
            ;;
        -h|--reg-host)
            shift # past argument
            REG_HOST="$1"
            shift # past value
            ;;
        -pa|--prune-all)
            shift # past argument
            PRUNE_ALL="$1"
            shift
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

# get some inspiration from:
#     https://gitlab.sas.com/adbull/documentation/-/blob/master/mirror_harbor.md#using-the-harbor-api

# $1=ordernum

# Confirm a param is being passed
# if [ "$ORDER" == "" ]; then
#   printf "You supplied the following ORDER number: $1\n"
# else
#   printf "You need to supply an Order Number. \n  Aborting\n"
#   exit 2
# fi


order=$(echo "${ORDER}" | awk '{print tolower($0)}')

echo ${ORDER}
echo ${order}

rm -rf ./${ORDER}

mkdir -p ./${ORDER}


#curl -k http://spsrest.fyi.sas.com:8081/comsat/orders/${ORDER}/view/soe/SAS_Viya_deployment_data.zip -o ./${ORDER}/SAS_Viya_deployment_data.zip
curl -k http://spsrest.fyi.sas.com:8081/comsat/orders/${ORDER}/view/soe/certs.zip -o ./${ORDER}/certs.zip

ls -al

#cp -f ~/mirrormgr.2020.04.27 ./${ORDER}/mirrormgr
#cp -f ~/mirrormgr.2020.05.04 ./${ORDER}/mirrormgr
cp -f ~/mirrormgr.2020.08.20 ./${ORDER}/mirrormgr

chmod 750 ./${ORDER}/mirrormgr

./${ORDER}/mirrormgr  --version


function prune_all (){
    if [[ "$PRUNE_ALL" == "1" ]] || [[ "$PRUNE_ALL" == "y" ]]; then
        docker system df
        docker image prune -a -f
        docker system df
    fi
}

prune_all

## get list of latest images
./${ORDER}/mirrormgr list remote docker tags --latest \
    --platform x64-oci-linux-2 \
    --deployment-data ./${ORDER}/certs.zip \
    | grep oci \
    | tee ./${ORDER}/imagelist.txt

## remove the "grep oci" below when https://rndjira.sas.com/browse/BAREOS-6798 is fixed
#CADENCE_VERSION=stable-2020.0.4

if [ "${CADENCE_VERSION}" != "" ]
then

    ## list all the cadences
    ./${ORDER}/mirrormgr list remote cadences  \
        --deployment-data ./${ORDER}/certs.zip \
        | tee ./${ORDER}/cadences.txt

    ## if a cadence was requested, and it matches with one in the list:
    if [ $( grep -c "${CADENCE_VERSION}" ./${ORDER}/cadences.txt) == 1 ]
    then
    ./${ORDER}/mirrormgr list remote docker tags \
        --cadence  ${CADENCE_VERSION} \
        --platform x64-oci-linux-2 \
        --deployment-data ./${ORDER}/certs.zip \
        | grep oci \
        | tee ./${ORDER}/imagelist.txt
    fi

fi

unzip -d ./${ORDER}/  ./${ORDER}/certs.zip

sudo mkdir -p /etc/docker/certs.d/ses.sas.download

sudo cp -v ./${ORDER}/ca-certificates/SAS_CA_Certificate.pem  /etc/docker/certs.d/ses.sas.download/ca.crt
sudo cp -v ./${ORDER}/entitlement-certificates/entitlement_certificate.pem /etc/docker/certs.d/ses.sas.download/client.cert
sudo cp -v ./${ORDER}/entitlement-certificates/entitlement_certificate.pem /etc/docker/certs.d/ses.sas.download/client.key

curl -kvL   --cacert ./${ORDER}/ca-certificates/SAS_CA_Certificate.pem \
            --cert ./${ORDER}/entitlement-certificates/entitlement_certificate.pem \
            https://ses.sas.download/ses/entitlements.json \
            -o ./${ORDER}/entitlements.json


# location=$( cat ./${ORDER}/order.oom | grep location | awk -F'"' '{print $4}' )
# username=$( cat ./${ORDER}/order.oom | grep username | awk -F'"' '{print $4}' )
# token=$( cat ./${ORDER}/order.oom | grep token | awk -F'"' '{print $4}' )

location=$( cat ./${ORDER}/entitlements.json | jq -r .registry.location )
username=$( cat ./${ORDER}/entitlements.json | jq -r .registry.username )
token=$( cat ./${ORDER}/entitlements.json | jq -r .registry.password )


## source registry
docker login -u ${username} -p ${token} ${location}

exit_if_bad

## Target registry
docker login -u ${REG_USER} -p ${REG_PASS} ${REG_HOST}

exit_if_bad


# for img in $(cat ./${ORDER}/imagelist.txt | grep -E 'stud|logon' )
# for img in $(cat ./${ORDER}/imagelist.txt | grep -i logon)
for img in $(cat ./${ORDER}/imagelist.txt )
do

    printf "\n-----------------------------------------------------------\n"
    cr_img=$(echo ${img} | sed -e "s/ses.sas.download/${location}/" )
    printf "\n Copying image $cr_img to ${REG_HOST}/${order}/ \n" | tee -a img.log

    printf "\n Pull \n"
    time docker image pull $cr_img
    exit_if_bad

    #remote_tag=$(echo $cr_img | sed -e "s|cr.sas.com/.*/|${REG_HOST}/${order}/|")
    remote_tag=$(echo $cr_img | sed -e "s|cr.sas.com/|${REG_HOST}/${order}/|")

    docker image  tag $cr_img $remote_tag

    printf "\n Push \n"
    time docker push $remote_tag
    exit_if_bad

    #DELETE_ON_THE_FLY
    #if [[ "$INGRESS_PREFIX" == "" ]] || [[ "$INGRESS_PREFIX" == "auto" ]]; then
    if [[ "$DELETE_ON_THE_FLY" == "1" ]] || [[ "$DELETE_ON_THE_FLY" == "y" ]]; then
        printf "\n Delete local image $cr_img \n" | tee -a img.log
        docker image rm $cr_img $remote_tag
    fi

done

prune_all
