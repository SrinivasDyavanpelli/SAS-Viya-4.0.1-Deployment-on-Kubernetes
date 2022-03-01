![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Connect your RACE machine to the Azure Kubernetes Cluster

## Introduction

At this point in the Hands-On, we will transform our RACE machine into a client of a much bigger Kubernetes Cluster.

This cluster will be created for you by the Workshop facilitator.

## Installing the Azure CLI binaries

1. First, let's get some YUM packages installed to help us:

    ```bash
    sudo yum install python \
        python36 \
        python-setuptools \
        python-devel \
        python2-virtualenv \
        openssl-devel \
        tmux \
        python-pip \
        gcc \
        wget \
        automake \
        libffi-devel \
        python-six \
        java \
          -y
    sudo pip install --upgrade pip
    sudo pip3.6 install --upgrade pip
    sudo pip3.6 install requests jinja2
    ```

1. Once we have these packages, we define a new YUM repository.

    ```bash
    sudo bash -c "cat > /etc/yum.repos.d/azure-cli.repo << EOF
    [azure-cli]
    name=Azure CLI
    baseurl=https://packages.microsoft.com/yumrepos/azure-cli
    enabled=0
    gpgcheck=1
    gpgkey=https://packages.microsoft.com/keys/microsoft.asc
    EOF"

    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

    ```

1. And now, finally, we can install the Azure CLI:

    ```bash
    sudo yum install --disablerepo=* --enablerepo=azure-cli azure-cli -y

    ```

1. So, now, let's check that we have the expected version

    ```bash
    az --version

    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    azure-cli                         2.0.81

    command-modules-nspkg              2.0.3
    core                              2.0.81
    nspkg                              3.0.4
    telemetry                          1.0.4

    Python location '/usr/bin/python3'
    Extensions directory '/home/cloud-user/.azure/cliextensions'

    Python (Linux) 3.6.8 (default, Aug  7 2019, 17:28:10)
    [GCC 4.8.5 20150623 (Red Hat 4.8.5-39)]

    Legal docs and information: aka.ms/AzureCliLegal

    Your CLI is up-to-date.

    Please let us know how we are doing: https://aka.ms/clihats
    ```

    </details>

## Installing the kubectl Binaries

1. Let's use the Azure CLI to install the Kubectl binaries

    ```bash
    sudo rm /usr/local/bin/kubectl
    sudo az aks install-cli
    ```

1. And now we can check which version we have:

    ```bash
    kubectl version --short
    ```

    <details><summary>Click here to see the expected output</summary>

    ```log
    [cloud-user@pdcesx04212 ~]$ kubectl version --short
    Client Version: v1.17.3
    The connection to the server localhost:8080 was refused - did you specify the right host or port?
    ```

    </details>

## Authenticating to Azure with the CLI

**NOTE: this is only for the teacher to do**

1. This Azure CLI now needs to be connected up to Azure.
1. For this, the teacher will set it up for the class.

    ```bash
    az login
    ```

## Student Differenciation

If someone has an Azure account, they will be able to execute this code, so we need to make sure that their name is on it.

1. Edit the text below to add your SAS user ID:

    ```bash
    echo 'erwan-granger' > ~/student.txt
    ```

1. Confirm that you entered your own user ID and not Erwan's

    ```bash
    export SAS_ID=$(cat ~/student.txt)
    if [ "$SAS_ID" = "erwan-granger" ] || [ "$SAS_ID" = "" ]
    then
        printf "\n\nNice Try! But that ($SAS_ID) is not your firstname-lastname. Go back and change it\n I am kicking you out\n"
    else
        printf "\n\nOk. Your name is ($SAS_ID). I'll take your word for it\n"
    fi

    ```

## Choosing the defaults

1. We need to define the location we want. Let's list the locations, and choose one:

    ```bash
    az account list-locations -o table
    az configure --defaults location=eastus
    ```

    <details><summary>Click here to see the sample output</summary>

    ```log
    [cloud-user@pdcesx04212 ~]$     az account list-locations -o table
    DisplayName           Latitude    Longitude    Name
    --------------------  ----------  -----------  ------------------
    East Asia             22.267      114.188      eastasia
    Southeast Asia        1.283       103.833      southeastasia
    Central US            41.5908     -93.6208     centralus
    East US               37.3719     -79.8164     eastus
    East US 2             36.6681     -78.3889     eastus2
    West US               37.783      -122.417     westus
    North Central US      41.8819     -87.6278     northcentralus
    South Central US      29.4167     -98.5        southcentralus
    North Europe          53.3478     -6.2597      northeurope
    West Europe           52.3667     4.9          westeurope
    Japan West            34.6939     135.5022     japanwest
    Japan East            35.68       139.77       japaneast
    Brazil South          -23.55      -46.633      brazilsouth
    Australia East        -33.86      151.2094     australiaeast
    Australia Southeast   -37.8136    144.9631     australiasoutheast
    South India           12.9822     80.1636      southindia
    Central India         18.5822     73.9197      centralindia
    West India            19.088      72.868       westindia
    Canada Central        43.653      -79.383      canadacentral
    Canada East           46.817      -71.217      canadaeast
    UK South              50.941      -0.799       uksouth
    UK West               53.427      -3.084       ukwest
    West Central US       40.890      -110.234     westcentralus
    West US 2             47.233      -119.852     westus2
    Korea Central         37.5665     126.9780     koreacentral
    Korea South           35.1796     129.0756     koreasouth
    France Central        46.3772     2.3730       francecentral
    France South          43.8345     2.1972       francesouth
    Australia Central     -35.3075    149.1244     australiacentral
    Australia Central 2   -35.3075    149.1244     australiacentral2
    UAE Central           24.466667   54.366669    uaecentral
    UAE North             25.266666   55.316666    uaenorth
    South Africa North    -25.731340  28.218370    southafricanorth
    South Africa West     -34.075691  18.843266    southafricawest
    Switzerland North     47.451542   8.564572     switzerlandnorth
    Switzerland West      46.204391   6.143158     switzerlandwest
    Germany North         53.073635   8.806422     germanynorth
    Germany West Central  50.110924   8.682127     germanywestcentral
    Norway West           58.969975   5.733107     norwaywest
    Norway East           59.913868   10.752245    norwayeast
    [cloud-user@pdcesx04212 ~]$     az configure --defaults location=eastus
    [cloud-user@pdcesx04212 ~]$
    ```

    </details>

1. Now, let's list the accounts we have access to and choose the default one:

    ```bash
    az account set -s "sas-gelsandbox"
    az account list -o table
    ```

   <details><summary>Click here to see the expected output</summary>

    ```log
    [cloud-user@pdcesx04212 ~]$     az account set -s "sas-gelsandbox"
    [cloud-user@pdcesx04212 ~]$     az account list -o table
    Name            CloudName    SubscriptionId                        State    IsDefault
    --------------  -----------  ------------------------------------  -------  -----------
    sas-gelsandbox  AzureCloud   c973059c-87f4-4d89-8724-a0da5fe4ad5c  Enabled  True
    Azure for PSD   AzureCloud   252972f2-a343-49b6-96d7-e619e918542a  Enabled  False
    GLE             AzureCloud   b91ae007-b39e-488f-bbbf-bc504d0a8917  Enabled  False
    sas-joswal      AzureCloud   cbfc8275-4cb1-407e-91f4-04cfb9478e05  Enabled  False
    Sandbox         AzureCloud   5509fbdf-fcde-4e29-be52-558b41db7221  Enabled  False
    [cloud-user@pdcesx04212 ~]$
    ```

   </details>

1. At this point, we will create a Resource Group, including the student name:

    ```bash
    az group create --name $(cat ~/student.txt)-RG
    az group wait --created  --resource-group $(cat ~/student.txt)-RG
    az group list -o table

    ```

   <details><summary>Click here to see the expected output</summary>

    ```log
    [cloud-user@pdcesx04212 ~]$     az group create --name $(cat ~/student.txt)-RG
    {
    "id": "/subscriptions/c973059c-87f4-4d89-8724-a0da5fe4ad5c/resourceGroups/erwan-granger-RG",
    "location": "eastus",
    "managedBy": null,
    "name": "erwan-granger-RG",
    "properties": {
        "provisioningState": "Succeeded"
    },
    "tags": null,
    "type": "Microsoft.Resources/resourceGroups"
    }
    [cloud-user@pdcesx04212 ~]$     az group wait --created  --resource-group $(cat ~/student.txt)-RG
    [cloud-user@pdcesx04212 ~]$     az group list -o table
    Name                      Location       Status
    ------------------------  -------------  ---------
    NetworkWatcherRG          australiaeast  Succeeded
    utkuma                    eastus2        Succeeded
    franir-RG                 eastus         Succeeded
    rocoll-RG                 eastus         Succeeded
    erwan-granger-RG          eastus         Succeeded
    DefaultResourceGroup-WUS  westus         Succeeded
    towalb-RG                 centralus      Succeeded
    [cloud-user@pdcesx04212 ~]$
    ```

   </details>

## Creating the cluster.

1. At this point, we can start the cluster:

    ```bash
   #az aks get-versions -o table

    time az aks create \
        --resource-group $(cat ~/student.txt)-RG \
        --name $(cat ~/student.txt)-Cluster \
        --dns-name-prefix $(cat ~/student.txt) \
        --enable-addons http_application_routing,monitoring \
        --load-balancer-sku standard \
        --kubernetes-version 1.15.7 \
        --node-count 10 \
        --nodepool-name egnp \
        --ssh-key-value ~/.ssh/cloud-user_id_rsa.pub

        # --node-vm-size Standard_D8s_v3 \


    ```

   <details><summary>Click here to see the expected output</summary>

    ```log
    {
    "aadProfile": null,
    "addonProfiles": null,
    "agentPoolProfiles": [
        {
        "availabilityZones": null,
        "count": 3,
        "enableAutoScaling": null,
        "enableNodePublicIp": null,
        "maxCount": null,
        "maxPods": 110,
        "minCount": null,
        "name": "nodepool1",
        "nodeLabels": null,
        "nodeTaints": null,
        "orchestratorVersion": "1.15.7",
        "osDiskSizeGb": 100,
        "osType": "Linux",
        "provisioningState": "Succeeded",
        "scaleSetEvictionPolicy": null,
        "scaleSetPriority": null,
        "tags": null,
        "type": "VirtualMachineScaleSets",
        "vmSize": "Standard_DS2_v2",
        "vnetSubnetId": null
        }
    ],
    "apiServerAccessProfile": null,
    "dnsPrefix": "erwan-gran-erwan-granger-RG-c97305",
    "enablePodSecurityPolicy": null,
    "enableRbac": true,
    "fqdn": "erwan-gran-erwan-granger-rg-c97305-87d5ba09.hcp.eastus.azmk8s.io",
    "id": "/subscriptions/c973059c-87f4-4d89-8724-a0da5fe4ad5c/resourcegroups/erwan-granger-RG/providers/Microsoft.ContainerService/managedClusters/erwan-granger-Cluster",
    "identity": null,
    "identityProfile": null,
    "kubernetesVersion": "1.15.7",
    "linuxProfile": {
        "adminUsername": "azureuser",
        "ssh": {
        "publicKeys": [
            {
            "keyData": "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDhw9+kXjLMdi1AnzYVfBbCa4L6cC1ebiW7UuAMB6vQUTMGHwrBRBbVZ23E2VdUsEGtEUk4qD1rpZRTrJRwnmaY3iEfRSOcrif1FOq8116r0unov8ne2RRYEI+PEYNCEnx/EiH38UBiNcsCxtNnW2BO3Cdq9nLzRjZr+OVookSCMlcFIiiMeMEh58F/Cx5LTt0LNUn4sgrnYHaoLtLvjddz9+igOKITnbIcNM2GK3ZkTdVZcfSeOyJUjcgdfqS7pG+o2DViMPv1Ttexu6s/aa1YuINvdWZOY/DYNyU0HF5ccOc9ewiiCTq0GU06dI1qWwoijiaZa808OwoZuvmWBlIz\n"
            }
        ]
        }
    },
    "location": "eastus",
    "maxAgentPools": 10,
    "name": "erwan-granger-Cluster",
    "networkProfile": {
        "dnsServiceIp": "10.0.0.10",
        "dockerBridgeCidr": "172.17.0.1/16",
        "loadBalancerProfile": {
        "allocatedOutboundPorts": null,
        "effectiveOutboundIps": [
            {
            "id": "/subscriptions/c973059c-87f4-4d89-8724-a0da5fe4ad5c/resourceGroups/MC_erwan-granger-RG_erwan-granger-Cluster_eastus/providers/Microsoft.Network/publicIPAddresses/99ffa275-9033-44b6-857c-774bf13d5323",
            "resourceGroup": "MC_erwan-granger-RG_erwan-granger-Cluster_eastus"
            }
        ],
        "idleTimeoutInMinutes": null,
        "managedOutboundIps": {
            "count": 1
        },
        "outboundIpPrefixes": null,
        "outboundIps": null
        },
        "loadBalancerSku": "Standard",
        "networkPlugin": "kubenet",
        "networkPolicy": null,
        "outboundType": "loadBalancer",
        "podCidr": "10.244.0.0/16",
        "serviceCidr": "10.0.0.0/16"
    },
    "nodeResourceGroup": "MC_erwan-granger-RG_erwan-granger-Cluster_eastus",
    "privateFqdn": null,
    "provisioningState": "Succeeded",
    "resourceGroup": "erwan-granger-RG",
    "servicePrincipalProfile": {
        "clientId": "8643d90f-bcf3-44f4-a758-4f3013b81c2b",
        "secret": null
    },
    "tags": null,
    "type": "Microsoft.ContainerService/ManagedClusters",
    "windowsProfile": null
    }

    real	6m55.877s
    user	0m1.728s
    sys	0m0.165s
    ```

   </details>

1. And now, to get the right config file for kubectl we execute:

    ```bash
    az aks get-credentials \
        --resource-group $(cat ~/student.txt)-RG \
        --name $(cat ~/student.txt)-Cluster \
        --overwrite-existing

    ```

1. Now, let's make sure the config file was properly created:

    ```bash
    cat /home/cloud-user/.kube/config
    cp /home/cloud-user/.kube/config /home/cloud-user/.kube/config_admin_aks
    ```

## nginx

1. create ingress namespace:

    ```bash
    kubectl create ns ingress-nginx

    kubectl --namespace=ingress-nginx apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/mandatory.yaml
    kubectl --namespace=ingress-nginx apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.29.0/deploy/static/provider/cloud-generic.yaml

    kubectl --namespace=ingress-nginx apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml

    curl -s https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml | sed '/^spec:/a \ \ loadBalancerSourceRanges:\n \ - <My-CIDR>' | kubectl --namespace=ingress-nginx apply -f -

    CLUSTER_RESOURCE_GROUP=$(az aks show --resource-group $(cat ~/student.txt)-RG --name $(cat ~/student.txt) --query nodeResourceGroup -o tsv)
    PUBLIC_IP_ID=$(az network public-ip list --resource-group $CLUSTER_RESOURCE_GROUP --query "[?tags.service=='ingress-nginx/ingress-nginx'].{id: id}" -o tsv)
    az network public-ip update --dns-name viya4azsukhda --ids $PUBLIC_IP_ID



    kubectl get svc -n ingress-nginx
    az network public-ip list -o table

    az network public-ip prefix list

    geltest.eastus.cloudapp.azure.com
    ```

## Create a load-balancer


## define a storage class:

    ```bash
    bash -c "cat << EOF > ~/az_rwx_storageclass.yaml
    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: azurefile
    provisioner: kubernetes.io/azure-file
    mountOptions:
      - dir_mode=0777
      - file_mode=0777
      - uid=1001
      - gid=1001
    parameters:
      skuName: Standard_LRS
    EOF"
    kubectl apply -f ~/az_rwx_storageclass.yaml

    kubectl patch storageclass default -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'

    kubectl patch storageclass azurefile -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

    ```

## Deleting the cluster

1. When we are done with this cluster, we execute the following to destroy it:

    ```bash
    time az aks delete \
        -g $(cat ~/student.txt)-RG \
        -n $(cat ~/student.txt)-Cluster
    ```

## Getting the credentials needed:

* do this step:

    ```bash
    mkdir -p .kube
    scp pdcesx04212.race.sas.com:/home/cloud-user/.kube/config .kube/config
    ```

az aks browse --resource-group $(cat ~/student.txt)-RG --name $(cat ~/student.txt)-Cluster --listen-address 0.0.0.0

<!--
	1. Create a Resource Group;
	az group create --location eastus --name aks-rg-sukhda

	2. Create the cluster;
	az aks create --name aks-cluster-sukhda --resource-group aks-rg-sukhda --dns-name-prefix sukhda --enable-addons http_application_routing,monitoring --load-balancer-sku standard --location eastus --node-count 5 --node-vm-size Standard_D8s_v3 --nodepool-name viya401

	*this command can sometimes throw a 400 error.  In that case just try again.  Seems fairly well documented online that first 2 out of 3 attempts can fail, seemingly at random.

	3. Setup Kubectl;
	az aks get-credentials --resource-group aks-rg-sukhda --name aks-cluster-sukhda

	4. Deploy Ingress;
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/mandatory.yaml
	curl -s https://raw.githubusercontent.com/kubernetes/ingress-nginx/nginx-0.30.0/deploy/static/provider/cloud-generic.yaml | sed '/^spec:/a \ \ loadBalancerSourceRanges:\n \ - <My-CIDR> | kubectl apply -f -

	5. Set a DNS name for the Ingress;
	CLUSTER_RESOURCE_GROUP=$(az aks show --resource-group aks-rg-sukhda --name aks-cluster-sukhda --query nodeResourceGroup -o tsv)
	PUBLIC_IP_ID=$(az network public-ip list --resource-group $CLUSTER_RESOURCE_GROUP --query "[?tags.service=='ingress-nginx/ingress-nginx'].{id: id}" -o tsv)
	az network public-ip update --dns-name viya4azsukhda --ids $PUBLIC_IP_ID

	6. Get the FQDN for the Ingress;
	az network public-ip show --ids $PUBLIC_IP_ID --query dnsSettings.fqdn -o tsv

	7. Deploy OpenLDAP into the Cluster;
	kubectl apply -f https://gitlab.sas.com/sukhda/viya-4.0.1/raw/master/azure/Resources/Manifests/openldap.yaml

	8. Deploy a new StorageClass;
	kubectl apply -f https://gitlab.sas.com/sukhda/viya-4.0.1/raw/master/azure/Resources/Manifests/StorageClass-RWX.yaml

Deploy Viya 4.0.1 -->