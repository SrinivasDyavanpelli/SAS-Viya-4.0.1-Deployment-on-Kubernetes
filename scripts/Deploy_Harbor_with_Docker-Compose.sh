#!/bin/bash

## Install Ansible
sudo yum install python-pip -y
sudo pip install --upgrade pip==19.3 setuptools==44.0
sudo pip install "ansible==2.9.2"
ansible --version

sudo mkdir -p /etc/ansible
sudo touch /etc/ansible/hosts
sudo touch /etc/ansible/ansible.cfg
sudo chmod 644 /etc/ansible/*

sudo tee /etc/ansible/ansible.cfg > /dev/null <<'EOF'
[defaults]

host_key_checking = false
# log_path = ./ansible_run.log
forks = 100

callback_whitelist = profile_tasks
[callback_profile_tasks ]
task_output_limit = 10
sort_order = descending
EOF


sudo tee /etc/ansible/hosts > /dev/null <<'EOF'
localhost        ansible_connection=local
EOF


ansible localhost -m ping


## Docker
mkdir -p /tmp/docker/install
cd  /tmp/docker/install
curl -fsSL https://get.docker.com -o get-docker.sh


cd  /tmp/docker/install
chmod 750 get-docker.sh
time sudo ./get-docker.sh

## No ansible?
ansible localhost -m group -a "name=docker state=present" -b --ask-become-pass
ansible localhost -m user  -a "name=cloud-user group=docker state=present" -b --diff
ansible localhost -m service -a "name=docker state=started enabled=yes" -b
##

sudo systemctl start docker
sudo /usr/sbin/usermod -aG docker canepg
sudo systemctl restart docker
sudo systemctl start docker

#log out and back in
#docker container run -it centos:7 bash


sudo yum install docker-compose -y

sudo yum update -y
# sudo yum -y install nfs-utils.x86_64


HARBOR_HTTP=80
HARBOR_HTTPS=443

# source <( cat /opt/raceutils/.bootstrap.txt  )
# source <( cat /opt/raceutils/.id.txt  )


## MFS Mount:

# ansible localhost \
# -m lineinfile -b \
# -a  "dest=/etc/fstab \
#     insertafter=EOF \
#     line='nagel01.unx.sas.com:/vol/gel/gate/mirrors/containers/    /mnt/containers/ nfs  noauto,user,defaults,exec 0 0' \
#     state=present \
#     backup=yes " \
#     --diff

# sudo mkdir /mnt/containers
# sudo mount /mnt/containers




## take care of the certs first:

sudo ansible localhost -m file -b -a \
"dest=/registry/ state=directory owner=root group=root mode=0755"
sudo ansible localhost -m file -b -a \
"dest=/registry/certs state=directory owner=glsuser1 group=unix_marketing mode=0755"
sudo ansible localhost -m file -b -a \
"dest=/registry/images state=directory owner=glsuser1 group=unix_marketing mode=0755"


long_hostname=gelharbor.race.sas.com
echo $long_hostname


sudo ansible localhost \
    -m get_url   -a \
        "url=https://gelweb.race.sas.com/scripts/gelregistry/certs/gelharbor.cer \
        dest=/registry/certs/gelharbor.cer \
        validate_certs=no \
        mode=0755 \
        backup=yes" \
            --diff



sudo ansible localhost \
    -m get_url   -a \
        "url=https://gelweb.race.sas.com/scripts/gelregistry/certs/gelharbor.key \
        dest=/registry/certs/gelharbor.key \
        validate_certs=no \
        mode=0755 \
        backup=yes" \
            --diff


sudo curl -k -o /etc/pki/ca-trust/source/anchors/SASRootCA.cer https://gelweb.race.sas.com/scripts/gelregistry/certs/SASRootCA.cer
sudo update-ca-trust

# if there is docker
sudo systemctl restart docker


# openssl req -newkey rsa:4096 -nodes -sha256 \
#     -keyout /registry/certs/domain.key -x509 -days 365 \
#     -out /registry/certs/domain.crt \
#     -subj "/C=US/ST=NC/L=Cary/O=SAS/OU=Harbor/CN=$long_hostname"

# ## distribute certs:
# ansible localhost  \
#     -b -m file \
#     -a "path=\"/etc/docker/certs.d/$long_hostname:$HARBOR_HTTPS/\" owner=root group=root state=directory mode=0750" \
#     --diff
# ansible localhost  \
#     -b -m file \
#     -a "path=\"/etc/docker/certs.d/$long_hostname/\" owner=root group=root state=directory mode=0750" \
#     --diff


# ansible localhost  \
#     -b -m copy \
#     -a "dest=\"/etc/docker/certs.d/$long_hostname:$HARBOR_HTTPS/ca.crt\" \
#         src=/registry/certs/domain.crt" \
#     --diff
# ansible localhost  \
#     -b -m copy \
#     -a "dest=\"/etc/docker/certs.d/$long_hostname/ca.crt\" \
#         src=/registry/certs/domain.crt" \
#     --diff

# ## restart docker
# ansible localhost  \
#     -b -m service \
#     -a "name=docker state=restarted enabled=y" \
#     --diff



## get Harbor payload
cd /tmp

sudo mkdir /registry/tmp/


sudo rm -rf /registry/tmp/harbor*

sudo ansible localhost \
    -m get_url \
    -a \
        "url=https://github.com/goharbor/harbor/releases/download/v1.10.1-rc1/harbor-offline-installer-v1.10.1-rc1.tgz \
        dest=/registry/tmp/harbor-offline-installer-v1.10.1-rc1.tgz \
        validate_certs=no \
        mode=0755 \
        backup=yes" \
            --diff

cd /registry/tmp
tar xvf harbor-offline-installer-v1.10.1-rc1.tgz
cd /registry/tmp/harbor/

## adjust files
sudo ansible localhost \
-m lineinfile \
-a  "dest=/registry/tmp/harbor/harbor.yml \
    regexp='^hostname:' \
    line='hostname: $long_hostname' \
    state=present \
    backup=yes " \
    --diff


ansible localhost \
-m lineinfile \
-a  "dest=/registry/tmp/harbor/harbor.yml \
    regexp='^  private_key:' \
    line='  private_key: /registry/certs/gelharbor.key' \
    state=present \
    backup=yes " \
    --diff

ansible localhost \
-m lineinfile \
-a  "dest=/registry/tmp/harbor/harbor.yml \
    regexp='^  certificate:' \
    line='  certificate: /registry/certs/gelharbor.cer' \
    state=present \
    backup=yes " \
    --diff

ansible localhost \
-m lineinfile \
-a  "dest=/registry/tmp/harbor/harbor.yml \
    regexp='^harbor_admin_password:' \
    line='harbor_admin_password: lnxsas' \
    state=present \
    backup=yes " \
    --diff

ansible localhost \
-m replace \
-a  "dest=/registry/tmp/harbor/harbor.yml \
    regexp='port: 443' \
    replace='port: $HARBOR_HTTPS' \
    backup=yes " \
    --diff


ansible localhost \
-m replace \
-a  "dest=/registry/tmp/harbor/harbor.yml \
    regexp='port: 80' \
    replace='port: $HARBOR_HTTP' \
    backup=yes " \
    --diff

ansible localhost \
-m lineinfile \
-a  "dest=/registry/tmp/harbor/harbor.yml \
    regexp='data_volume:' \
    line='data_volume: /registry/images' \
    backup=yes " \
    --diff



##kick off harbor install

cd /registry/tmp/harbor
#pygmentize harbor.yml

sudo /registry/tmp/harbor/install.sh

# printf "* [Harbor URL](https://gelharbor.race.sas.com/ )\n" | \
    # tee -a ~/urls.md

fi

docker login $(hostname -f):443 -u admin -p lnxsas

# docker login $(hostname -f)
#     u: admin
#     p: lnxsas

    docker pull centos:7
    docker tag centos:7 $(hostname -f)/library/centos:7
    docker push  $(hostname -f)/library/centos:7



