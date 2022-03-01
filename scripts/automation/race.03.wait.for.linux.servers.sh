#!/bin/bash

# while [[ $# -gt 0 ]]; do
#     key="$1"
#     case ${key} in
#         -ri|--reservation-id)
#             shift
#             RESERVATION_ID="${1}"
#             shift
#             ;;
#         -u|--user)
#             shift
#             USER_ID="${1}"
#             shift
#             ;;
#         -p|--pass)
#             shift
#             USER_PASS="${1}"
#             shift
#             ;;
#         --retries)
#             shift
#             NUMBER_OF_RETRIES="${1}"
#             shift
#             ;;
#         --sleep)
#             shift
#             SLEEP_BETWEEN_RETRIES="${1}"
#             shift
#             ;;

#         *)
#             echo -e "\n\nOne or more arguments were not recognized: \n$@"
#             echo
#             exit 1
#             shift
#     ;;
#     esac
# done




bash -c "cat << EOF > wait_for_servers.yaml
---
- hosts: all
  #gather_facts: no
  tasks:
    - name: Wait for all machines to be reachable (up to 1800 seconds, aka 30 minutes)
      any_errors_fatal: false
      wait_for_connection:
        timeout: 1800

    - ping:

    - name: grab the content of the /etc/hosts
      shell: cat /etc/hosts
      register: etc_hosts
      changed_when: false

    - name: show the content
      debug: var=etc_hosts

EOF"

ansible-playbook ./wait_for_servers.yaml
