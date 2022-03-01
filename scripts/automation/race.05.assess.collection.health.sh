#!/bin/bash

#h=pdcesx03211.race.sas.com
#/Users/canepg/Documents/git_projects/gitlab/remoter/remoter.sh  -h $h -s /Users/canepg/Documents/git_projects/gitlab/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/ -u cloud-user -d /tmp/scripts/ -c "/tmp/scripts/automation/race.05.assess.collection.health.sh " -w


INV="SIMSService --status=any  | awk -F'[ :]' '{print \$2 \" ansible_host=\" \$1}'  | grep -v sasclient | sort"

echo $INV

ansible all[0] -m shell -a "$INV" | grep ansible_host > inv.ini

cat inv.ini

ansible -i ./inv.ini sasnode01 -m shell -a "hostname -f"

tee  ./work.yaml > /dev/null << "EOF"
---
- hosts: sasnode01
  gather_facts: no
  tasks:
    - name: Wait for all machines to be reachable (up to 1800 seconds, aka 30 minutes)
      any_errors_fatal: false
      wait_for_connection:
        timeout: 1800

    - name: delete namespace
      shell: |
        printf "running on $(hostname -f) $(hostname -i)\n"
        time kubectl delete ns dailymirror || true
      register: del_ns
    - name: show the content
      debug: var=del_ns

    - name: refresh cheatcodes
      shell: |
        cd ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/
        git pull
        bash scripts/loop/GEL.02.CreateCheatcodes.sh start
      register: cc_refresh
    - name: show the content
      debug: var=cc_refresh

    - name: kickoff dailymirror deployment
      shell: |
        cd ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/
        time bash -x 05_Deployment_tools/96_deploy_dailymirror.sh
      register: kickoff
    - name: show the content
      debug: var=kickoff

    - name: wait for dailymirror deployment to be up.
      shell: |
        cd ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/
        time bash 06_Deployment_Steps/gel_OKViya4.sh -n dailymirror --wait
      register: wait_daily
    - name: show the content
      debug: var=wait_daily
EOF

ansible-playbook -i ./inv.ini ./work.yaml
