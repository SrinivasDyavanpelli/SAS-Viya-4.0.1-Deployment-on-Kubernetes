#!/bin/bash

timestamp() {
  date +"%T"
}
datestamp() {
  date +"%D"
}

function logit () {
    sudo touch ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
    sudo chmod 777 ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
    printf "$(datestamp) $(timestamp): $1 \n"  | tee -a ${RACEUTILS_PATH}/logs/${HOSTNAME}.bootstrap.log
}

## Read in the id file. only really needed if running these scripts in standalone mode.
source <( cat /opt/raceutils/.bootstrap.txt  )
source <( cat /opt/raceutils/.id.txt  )
reboot_count=$(cat /opt/raceutils/.reboot.txt)

sudo tee  /tmp/urls_update.sh > /dev/null << "EOF"
#!/bin/bash

#PATT="\(pdcesx\|rext\)[^ ]*\.race\.sas\.com"
PATT="\(pdcesx\|rext\|aznvir\)[^ ]*\.race\.sas\.com"

if [  -f /home/cloud-user/urls.md ]; then
    HEAD1="# List of URLs for your environment"
    ## remove header:
    sudo -u cloud-user bash -c  "sed -i '/$HEAD1/d' ~/urls.md"

    # sort and remove dupes
    sudo -u cloud-user bash -c  "sort -u  ~/urls.md  -o ~/urls.md"

    # add header back in:
    sudo -u cloud-user bash -c  "sed -i '1s/^/${HEAD1} \n/' ~/urls.md"

    echo "Before: $(egrep "pdce|rext|aznvir" ~/urls.md)"
    sudo -u cloud-user bash -c  "sed -i \"s/${PATT}/$(hostname -f)/g\" ~/urls.md"
    echo "After: $(egrep "pdce|rext|aznvir" ~/urls.md)"
fi
EOF

sudo chmod 777 /tmp/urls_update.sh

sudo tee  /tmp/cron_urls_update.yaml > /dev/null << "EOF"
---
- hosts: localhost
  tasks:
    - name: cron the url clean routine
      become: yes
      cron:
        name: "clean and update the URLs file "
        minute: "*/5"
        hour: "*"
        job: "/tmp/urls_update.sh"
      register: crontab
    - debug: var=crontab

EOF

# find all files
find /home/cloud-user -type f -not -path "*.git/*" -not -path "*.ssh/*"

# Tip Run this command to check Before and after (grep use regular expressions!)
grep -rnw '/home/cloud-user' -e  '\<pdc.*race.sas.com\>' -e '\<rext.*race.sas.com\>' -e '\<aznvir.*race.sas.com\>' \
| grep -v '.cache' \
| grep -v 'PSGEL' \
| grep -v ".bash_history" \
| grep -v .git \
| grep -v known_hosts

# Get the manifest files and replace:
sudo tee  /tmp/manifests_update.sh > /dev/null << "EOF"
#!/bin/bash

# FILES=$(find /home/cloud-user -type f -not -path "*.git/*" -not -path "*.ssh/*" -not -path "*.md" -not -path "*.bash_history*" )
FILES=$(find /home/cloud-user/project /home/cloud-user/esp-kubernetes -type f )

#PATT="\(pdcesx\|rext\)\(\w*\|\d*-\d*\)\.race\.sas\.com"
#PATT="\(pdcesx\|rext\)[^ ]*\.race\.sas\.com"
PATT="\(pdcesx\|rext\|aznvir\)[^ ]*\.race\.sas\.com"

for f in $FILES
do
  #echo "Processing $f file..."
  if grep -q "${PATT}" "$f"; then
   #echo "file $f contains 'race.sas.com'"
   #grep "${PATT}" "$f"
   echo "Before: $(egrep "pdce|rext|aznvir" $f)"
   sed -i "s/${PATT}/$(hostname -f)/g" $f
   echo "After: $(egrep "pdce|rext|aznvir" $f)"
  fi
done

EOF

# Check After : the command should return NOTHING because we exclude the correct hostname value
grep -rnw '/home/cloud-user' -e  '\<pdc.*race.sas.com\>' -e '\<rext.*race.sas.com\>' -e '\<aznvir.*race.sas.com\>' \
| grep -v '.cache' \
| grep -v 'PSGEL' \
| grep -v ".bash_history" \
| grep -v .git \
| grep -v known_hosts \
| grep -v "$(hostname -f)"
# to do : test the rc if empty good otherwhise break.

sudo chmod 777 /tmp/manifests_update.sh

sudo tee  /tmp/k_objects_update.sh > /dev/null << "EOF"
#!/bin/bash

#PATT="\(pdcesx\|rext\)\(\w*\|\d*-\d*\)\.race\.sas\.com"
#PATT="\(pdcesx\|rext\)[^ ]*\.race\.sas\.com"
PATT="\(pdcesx\|rext\|aznvir\)[^ ]*\.race\.sas\.com"

K_OBJECTS="ing,deploy,rs"

kubectl get ${K_OBJECTS} -A -o yaml \
| sed "s/${PATT}/$(hostname -f)/g" \
| kubectl replace -f -

EOF

sudo chmod 777 /tmp/k_objects_update.sh

# harness test for search and replace pattern
# echo "    - host: espmeter.sasesp.aznvir01002.race.sas.com" | sed "s/\(pdcesx\|rext\|aznvir\)[^ ]*\.race\.sas\.com/$(hostname -f)/g"


case "$1" in
    'enable')

    ;;
    'dev')

    ;;

    'start')
        if [ "$race_alias" == "sasnode01" ]  ;     then

        cd /tmp/
        sudo -u cloud-user bash -c "cd /tmp/ ; /tmp/urls_update.sh >> /tmp/urls_update.log"
        sudo -u cloud-user bash -c "cd /tmp/ ; ansible-playbook /tmp/cron_urls_update.yaml"

        if [ "$reboot_count" -gt "1" ] ; then
        sudo -u cloud-user bash -c "cd /tmp/ ; /tmp/manifests_update.sh >> /tmp/manifests_update.log"
        sudo -u cloud-user bash -c "cd /tmp/ ; /tmp/k_objects_update.sh >> /tmp/k_objects_update.log"
        fi

        fi
    ;;

    'stop')

    ;;
    'clean')

    ;;

    *)
        printf "Usage: GEL.00.Clone.Project.sh {enable/start|stop|clean} \n"
        exit 1
    ;;
esac
