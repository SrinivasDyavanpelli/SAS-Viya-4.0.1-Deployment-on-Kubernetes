#!/bin/bash

## if there was an existing version, we delete it, to be safe
sudo rm -rf /opt/raceutils/

## let's not assume it will always be the master branch of raceutils:
RACEUTILS_BRANCH=master

## just in case:
sudo git config --global http.sslVerify "false"

## now we clone
sudo git clone --branch $RACEUTILS_BRANCH https://gelgitlab.race.sas.com/GEL/utilities/raceutils.git /opt/raceutils
