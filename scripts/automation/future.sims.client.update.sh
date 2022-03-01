
# from: https://perc.na.sas.com/doc/Applications/Wintel/SIMS/SIMS_Programmer_Docs.html#SIMSAgentLinux

# old client:
ansible sasnode* -m shell -b -a "cd /tmp ; \
    alias /bin/sh='/usr/bin/sh' ; \
    wget --timeout=3 --tries=1 -q -O /tmp/SIMSService-latest.sh http://sodsched1.exnet.sas.com/ClientUpdater/LinuxUnixAgent/SIMSService-latest.sh ;\
    systemctl stop sims ;\
    sh  /tmp/SIMSService-latest.sh ;\
    systemctl start sims "

ansible sasnode* -m shell -b -a "SIMSService --status=any | wc -l"
ansible sasnode* -m shell -b -a "SIMSService "

# new client
ansible sasnode* -m shell -b -a "cd /tmp ; \
    wget --timeout=3 --tries=1 -O SIMSService-go-latest.sh http://sodsched1.exnet.sas.com/ClientUpdater/LinuxUnixAgent/SIMSService-go-latest.sh ;\
    sed -i 's|'\/bin\/sh'|/usr/bin/sh|g' SIMSService-go-latest.sh ;\
    systemctl stop sims ;\
    sh  SIMSService-go-latest.sh ;\
    systemctl start sims "

ansible sasnode* -m shell -b -a "SIMSService --status"
