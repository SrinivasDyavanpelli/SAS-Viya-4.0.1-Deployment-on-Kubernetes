#!/bin/bash

curl -k https://gelweb.race.sas.com/scripts/PSGEL255/orders/$(cat ~/stable_order.txt)_kustomize_default.tgz \
    -o /tmp/kustomize.tgz

cd /tmp
tar xf kustomize.tgz

for f1 in $(find  /tmp/sas-bases/  -name "*.md" | grep -v "ignore"  | sort )
do
    echo ${f1}

done

cd /tmp/sas-bases


docker pull functions/markdown-render:latest
docker run


docker pull v4tech/markdown-editor

docker container run \
    -p 12345:80 --rm -it \
    -v a:b \
    v4tech/markdown-editor


docker pull benweet/stackedit

docker container run \
    --name se \
    --rm -it \
    -v /home/cloud-user/project/deploy/lab/sas-bases:/opt/stackedit
    -p 8080:8080 \
     benweet/stackedit

# Enables editing in Gollum
docker run -p 4567:80 -v /home/cloud-user/project/deploy/lab/sas-bases:/wiki mrburrito/gfm edit

docker container run \
    --rm \
    -v /home/cloud-user/project/deploy/testready/sas-bases:/root/docs \
    -p 6419:6419 \
    -t \
    -i fstab/grip \
    grip /root/docs/README.md 0.0.0.0:6419

Coming to "grip" with markdown
