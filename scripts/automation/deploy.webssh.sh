#!/bin/bash

sudo pip install --upgrade pip
sudo pip install wheel webssh

nohup wssh --address='0.0.0.0' --port=2222 &

printf "http://$(hostname -f):2222/?hostname=localhost&username=cloud-user&password=bG54c2Fz \n"

# http://localhost:8888/?hostname=xx&username=yy&password=str_base64_encoded
