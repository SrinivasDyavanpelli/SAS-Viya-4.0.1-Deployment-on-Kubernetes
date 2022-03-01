![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# bootstrapping the RACE Machine for this project

This is what needs to be run to enable the git project on the machine.

```sh
# one liner:
curl -fsSL https://gelgitlab.race.sas.com/GEL/utilities/raceutils/raw/master/bootstrap/bootstrap.collection.sh | \
    sudo bash -s enable https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes.git master

curl -fsSL https://gelgitlab.race.sas.com/GEL/utilities/raceutils/raw/master/bootstrap/bootstrap.collection.sh | \
    sudo bash -s start

ansible sasnode* -m shell -a "curl -fsSL https://gelgitlab.race.sas.com/GEL/utilities/raceutils/raw/master/bootstrap/bootstrap.collection.sh |  sudo bash -s enable https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes.git master "

#sudo bash  /tmp/bootstrap.collection.sh start
sudo -u cloud-user bash -c "ansible  sasnode*  -m shell -a 'echo 0 > /opt/raceutils/.reboot.txt ' -b "

```

This is for Erwan to sync local project to target server.

```sh
#!/bin/bash

SessName=rsync

tmux new -s $SessName -d

h=rext03-0030.race.sas.com
tmux send-keys -t $SessName "/Users/canepg/Documents/git_projects/gitlab/remoter/remoter.sh -h $h -s /Users/canepg/Documents/git_projects/gitlab/PSGEL255-deploying-viya-4.0.1-on-kubernetes/ -u cloud-user -d /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/ -c \"/home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.02.CreateCheatcodes.sh start \" -w "  C-m

h=pdcesx03011.race.sas.com
    tmux split-window -h -t $SessName
tmux send-keys -t $SessName "/Users/canepg/Documents/git_projects/gitlab/remoter/remoter.sh -h $h -s /Users/canepg/Documents/git_projects/gitlab/PSGEL255-deploying-viya-4.0.1-on-kubernetes/ -u cloud-user -d /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/ -c \"/home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.02.CreateCheatcodes.sh start\" -w "  C-m

h=pdcesx02209.race.sas.com
tmux split-window -v -t $SessName.0
tmux send-keys -t $SessName "ssh cloud-user@$h"  C-m

h=rext03-0228.race.sas.com
tmux split-window -v -t $SessName.2
tmux send-keys -t $SessName "ssh cloud-user@$h"  C-m

tmux attach -t $SessName

exit
tmux kill-session -t rsync

```

```sh
ansible sasnode* -m shell -a "cat /usr/lib/systemd/system/docker.service"
```

cd ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop
for f in ./GEL*.sh   ; do
    echo  "sudo bash $f start "
done

* simult reboot:

    ```sh
    ansible sasnode* -m shell -b -a 'echo "reboot now" | at now + 1 min'

    # better way:
    TARG="sasnode02,sasnode03,sasnode04,sasnode05,sasnode06,sasnode07,sasnode08,sasnode09,sasnode10,sasnode11"

    ansible ${TARG} -m shell -b -a 'echo 1 > /proc/sys/kernel/sysrq '
    ansible ${TARG} -m shell -b -a ' echo "echo b > /proc/sysrq-trigger " | at now + 1 min'

    ```

* review logs afer boot:

```sh
sudo journalctl -u bootstrap.collection.service --no-pager | less
```


## VIP Tunnels

Bootstrap before saving coll

```sh
curl -fsSL https://gelgitlab.race.sas.com/GEL/utilities/raceutils/raw/master/bootstrap/bootstrap.collection.sh | \
    sudo bash -s enable https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes.git vip_tunnels_work

ansible sasnode* -m shell -a "curl -fsSL https://gelgitlab.race.sas.com/GEL/utilities/raceutils/raw/master/bootstrap/bootstrap.collection.sh |  sudo bash -s enable https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes.git vip_tunnels_work "

#sudo bash  /tmp/bootstrap.collection.sh start
            sudo -u cloud-user bash -c "ansible  sasnode*  -m shell -a 'echo 0 > /opt/raceutils/.reboot.txt ' -b "

```

Simulate a collection rebook

```sh
curl -fsSL https://gelgitlab.race.sas.com/GEL/utilities/raceutils/raw/master/bootstrap/bootstrap.collection.sh | \
    sudo bash -s start

```

## testing commands

cd ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes
git pull
cd ~

ansible-playbook ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/playbooks/VIP_tunnels.yaml --step

```bash
ansible sasnode* -m shell \
    -a "curl -fsSL https://gelgitlab.race.sas.com/GEL/utilities/raceutils/raw/master/bootstrap/bootstrap.collection.sh | \
     sudo bash -s enable https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes.git vip_tunnels_work "


sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.01.CloneProject.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.02.CreateCheatcodes.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.03.StageMachine.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.04.1.Ansible.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.04.2.VIP_tunnels.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.05.Docker.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.06.Kubectl.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.07.K8S.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.08.Helm.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.09.Ingress.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.10.Kustomize.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.11.Persistence.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.12.Rancher.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.13.Weave.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.14.CleanUsers.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.15.DefineAliases.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.21.PrePullImages.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.30.Autorun.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.50.Monitoring.sh start
sudo bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.99.TheEnd.sh start

```

## Erwan quick testing steps

```bash

    qt=/tmp/quicktest
    PROJ=PSGEL255-deploying-viya-4.0.1-on-kubernetes
    GIT_CLONE_URL=https://gelgitlab.race.sas.com/GEL/workshops/${PROJ}.git
    BRANCH=mirror_2

    rm -rf ${qt}
    mkdir ${qt}
    cd ${qt}
    git clone --branch $BRANCH $GIT_CLONE_URL
    cd ${qt}/${PROJ}

    git fetch --all
    git reset --hard origin/${BRANCH}

    /opt/raceutils/cheatcodes/create.cheatcodes.sh .
    #bash ./scripts/loop/GEL.02.CreateCheatcodes.sh start

    #bash -x ${qt}/${PROJ}/05_*/05_011*.sh
    bash -x ${qt}/${PROJ}/05_*/05_012*.sh
    #bash -x ${qt}/${PROJ}/06_Deployment_Steps/02_Deploying_Viya_with_Authentication.sh

```
