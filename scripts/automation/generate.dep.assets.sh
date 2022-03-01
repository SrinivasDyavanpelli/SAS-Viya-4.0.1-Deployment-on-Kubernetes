#!/bin/bash



### sample execution:

# ./generate.dep.assets.sh --help
# ./generate.dep.assets.sh
#    --order <9cdzdd)
#    --cadence
#    --cadence-name stable \
#    --cadence-version 2020.0.6 \
#    --cadence-release latest \
#    --order-cli-release 0.2.0
#    --api-key .....
#    --api-secret
#
# https://github.com/sassoftware/viya4-orders-cli/releases/download/0.2.0/viya4-orders-cli_linux_amd64


#### code goes here:

# sytnthax check
while [[ $# -gt 0 ]]; do
    key="$1"
    case ${key} in
        -o|--order)
            shift
            ORDER="${1}"
            shift
            ;;
        -cn|--cadence-name)
            shift
            CADENCE="${1}"
            shift
            ;;
        -cv|--cadence-version)
            shift
            VERSION="${1}"
            shift
            ;;
        -cr|--cadence-release)
            shift
            RELEASE="${1}"
            shift
            ;;
        -ocr|--order-cli-release)
            shift
            ORDERCLIRELEASE="${1}"
            shift
            ;;
        -ak|--api-key)
            shift
            APIKEY="${1}"
            shift
            ;;
        -as|--api-secret)
            shift
            APISECRET="${1}"
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

# get binary
# IMPORTANT github credentials needs to be configured in Jenkins for that...
#git config user.name "raphaelpoumarede"
#git config user.password "your password"
#git clone https://github.com/sassoftware/viya4-orders-cli/releases/download/0.2.0/viya4-orders-cli_linux_amd64


# generate latest assets
export APIKEY=
export APISECRET=
viya4-orders-cli_linux_amd64  dep $ORDER $CADENCE $VERSION
