![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Creating a Viya 4 Order

1. makeorder
1. select VA
1. create Order.

![alt](./img/MakeOrder.png)

## order management

creating an order.

<http://comsat.sas.com/#order=09QPCD>

making it external:

<https://rndconfluence.sas.com/confluence/display/RLSENG/Accessing+internal+container+images+from+external+locations>

| | |
|--|-|
| Registry Hostname | cr.sas.com                                |
| Username:         | p-II4qJKFQ43Ak                            |
| Password:         | uqJR19bjha0388jExJdTXr-fQKxMI5ia7hYGTIno  |

## docker login


docker login cr.sas.com -u p-II4qJKFQ43Ak -p uqJR19bjha0388jExJdTXr-fQKxMI5ia7hYGTIno



./mirrormgr list remote repos --deployment-data SAS_Viya_deployment_data.zip

./mirrormgr list remote platforms --deployment-data SAS_Viya_deployment_data.zip

./mirrormgr list remote docker tags --deployment-data SAS_Viya_deployment_data.zip --latest --debug



wget http://delphi.unx.sas.com/~elliot/mirrormgr.docker
chmod a+x mirrormgr.docker


* this is what you need to do so that your machine starts to trust the gel registry

```sh
sudo curl -k -o /etc/pki/ca-trust/source/anchors/SASRootCA.cer https://gelweb.race.sas.com/scripts/gelregistry/certs/SASRootCA.cer
sudo update-ca-trust
sudo systemctl restart docker
```

# and then you can push images to it.
docker image pull centos:7
docker image tag centos:7 gelregistry.exnet.sas.com:5001/centos:7
docker image push gelregistry.exnet.sas.com:5001/centos:7


* on openstack box:



./mirrormgr.docker mirror registry -k --destination gelregistry.exnet.sas.com:5001/09QH4Z --workers 1 --deployment-data ./SAS_Viya_deployment_data.zip


docker login gelregistry.exnet.sas.com:5001 -u me -p me

./mirrormgr.docker mirror registry -k --destination gelregistry.exnet.sas.com:5001/09QH4Z --workers 4 --deployment-data ./SAS_Viya_deployment_data.zip


./mirrormgr mirror registry -k --destination gelregistry.exnet.sas.com:5001/09qj8q --workers 1 --deployment-data ./SAS_Viya_deployment_data.09QJ8Q.zip


