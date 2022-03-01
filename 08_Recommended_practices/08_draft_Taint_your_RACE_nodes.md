![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

```bash

kubectl label nodes \
    intnode03 \
    intnode04 \
    intnode05 \
    workload.sas.com/class=cas --overwrite



kubectl label nodes \
    intnode01 \
    workload.sas.com/class=stateless --overwrite

kubectl label nodes \
    intnode02 \
    workload.sas.com/class=stateful --overwrite

kubectl label nodes \
    intnode03 \
    workload.sas.com/class=compute --overwrite

kubectl label nodes \
    intnode04 \
    workload.sas.com/class=cas --overwrite



kubectl taint nodes \
    intnode01 \
    workload.sas.com/class=stateless:NoSchedule \
    --overwrite

kubectl taint nodes \
    intnode02 \
    workload.sas.com/class=stateful:NoSchedule --overwrite

kubectl taint nodes \
    intnode03 \
    workload.sas.com/class=compute:NoSchedule --overwrite

kubectl taint nodes \
    intnode04 \
    workload.sas.com/class=cas:NoSchedule --overwrite

#untaint

kubectl taint nodes \
    intnode01 \
    intnode02 \
    workload.sas.com/class=stateless:NoSchedule- --overwrite

kubectl taint nodes \
    intnode03 \
    workload.sas.com/class=stateful:NoSchedule- --overwrite

kubectl taint nodes \
    intnode04 \
    workload.sas.com/class=compute:NoSchedule- --overwrite

kubectl taint nodes \
    intnode05 \
    workload.sas.com/class=cas:NoSchedule- --overwrite

pod-auto-scaler: adds more pods if there are not enough replicas.

node auto-scaler based on requests? based on busyness of node?

making sure it won't scale in on us.

100 users -> cluster scales to 10 nodes.
99 people stop working -> does it generate downtime for the 1 user still.



    workload.sas.com/class: cas
    workload.sas.com/class: compute
        workload.sas.com/class: stateful
    workload.sas.com/class: stateful
        workload.sas.com/class: stateless
    workload.sas.com/class: stateless



kubectl label nodes vde162.unx.sas.com vde163.unx.sas.com vde164.unx.sas.com vde169.unx.sas.com vde170.unx.sas.com workload.sas.com/class=cas --overwrite
node/vde162.unx.sas.com labeled
node/vde163.unx.sas.com labeled
node/vde164.unx.sas.com labeled
node/vde169.unx.sas.com labeled
node/vde170.unx.sas.com labeled
kubectl taint nodes vde162.unx.sas.com vde163.unx.sas.com vde164.unx.sas.com vde169.unx.sas.com vde170.unx.sas.com workload.sas.com/class=cas:NoSchedule --overwrite
node/vde162.unx.sas.com modified
node/vde163.unx.sas.com modified
node/vde164.unx.sas.com modified
node/vde169.unx.sas.com modified
node/vde170.unx.sas.com modified
kubectl label nodes vde173.unx.sas.com workload.sas.com/class=compute --overwrite
node/vde173.unx.sas.com labeled
kubectl taint nodes vde173.unx.sas.com workload.sas.com/class=compute:NoSchedule --overwrite
node/vde173.unx.sas.com modified
kubectl label nodes vde174.unx.sas.com workload.sas.com/class=stateful --overwrite
node/vde174.unx.sas.com labeled
kubectl taint nodes vde174.unx.sas.com workload.sas.com/class=stateful:NoSchedule --overwrite
node/vde174.unx.sas.com modified
kubectl label nodes vde175.unx.sas.com workload.sas.com/class=stateless --overwrite
node/vde175.unx.sas.com labeled
kubectl taint nodes vde175.unx.sas.com workload.sas.com/class=stateless:NoSchedule --overwrite
node/vde175.unx.sas.com modified
kubectl uncordon vde162.unx.sas.com vde163.unx.sas.com vde164.unx.sas.com vde169.unx.sas.com vde170.unx.sas.com vde173.unx.sas.com vde174.unx.sas.com vde175.unx.sas.com
node/vde162.unx.sas.com uncordoned
node/vde163.unx.sas.com uncordoned
node/vde164.unx.sas.com uncordoned
node/vde169.unx.sas.com uncordoned
node/vde170.unx.sas.com uncordoned
node/vde173.unx.sas.com uncordoned
node/vde174.unx.sas.com uncordoned
node/vde175.unx.sas.com uncordoned
```