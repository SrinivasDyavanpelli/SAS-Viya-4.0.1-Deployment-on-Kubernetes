#!/bin/bash

waitforbootstrap () {

    LOGFILE=/opt/raceutils/logs/$(hostname).bootstrap.log

    # while ! grep "GEL.99.TheEnd.sh" ${LOGFILE};do echo "Bootsrap not finished yet";sleep 2;done

    while ! grep -q "GEL.99.TheEnd.sh" ${LOGFILE}; do
        tail -n5 ${LOGFILE}
        printf "\nBoostrap has not finished yet\n"
        sleep 5
    done
    cat ${LOGFILE}
    printf "\nBoostrap has finished on $(hostname -f) ( $(cat /opt/raceutils/.id.txt | grep alias) )  \n"

}

waitforbootstrap
