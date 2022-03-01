![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Tests with CAS DISK CACHE

Create fake drives:

```bash
ansible sasnode* -m file -b -a "path=/mnt-nvme0 mode=0777 state=directory"
ansible sasnode* -m file -b -a "path=/mnt-nvme1 mode=0777 state=directory"

```

restart CAS

```bash
NS=gelenv-stable
kubectl -n ${NS} delete pods -l casoperator.sas.com/server=default
```

```bash
# check CDC on all nodes
ansible sasnode* -m shell -b -a ' lsof -nP -c cas  2>/dev/null |  grep "(deleted)" ' | grep casmap


```

```sas

cas erwan;


data bigair;
set sashelp.air;
do i = 1 to 1000000;
    output;
end;
run;

proc contents data=work._all_;
run;

proc casutil;
    load data=bigair outcaslib="casuser"
    casout="a" replace ;
run;



```




# Topics:

* Recommendations and sequence ...
  * emptydir is default
    * But ...
    * Apparently Limited to 50GB each on Azure (https://docs.microsoft.com/en-us/azure/container-instances/container-instances-volume-emptydir)
    * goes to /var/lib/docker ... might impact the entire node.
  * What is the second default?
    * HostPath is insecure and probably forbidden by customers who understand the implications.

David page says:
gonna raise this point everywhere to anyone that will listen - hostPaths are going to be outlawed by most customers with any k8s experience - they are a huge security risk since there's no way to provide a list of what paths are okay to mount, and which aren't. So while we may only ever mount /tmp/work or whatever - if the launcher service (or anything with service account permissions to launch pods) is compromised, it can be used to launch pods that mount /proc and break out of the chroot jail and compromise the underlying nodes as well as other pods in other namespaces
https://blog.appsecco.com/kubernetes-namespace-breakout-using-insecure-host-path-volume-part-1-b382f2a6e216

so .. document but caveat.

what are the other options?

* documentation issues:
  * YAML is missing the "targets" blocks.
  * Online doc sample YAML is completely different from what's int the ./sas-bases/examples


Type: directory causes issues in our testing:
https://github.com/kubernetes/kubernetes/issues/83125


DOC:

ephemeral sections:
http://pubshelpcenter.unx.sas.com:8080/test/?cdcId=itopscdc&cdcVersion=v_006&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm&locale=en#p0mcnfmgpaspzbn11h9rcw8mc2lh

CDC section

http://pubshelpcenter.unx.sas.com:8080/test/?cdcId=itopscdc&cdcVersion=v_006&docsetId=dplyml0phy0dkr&docsetTarget=n08u2yg8tdkb4jn18u8zsi6yfv3d.htm&locale=en#p0wtwirnp4uayln19psyon1rkkr9

cat sas-bases/examples/cas/configure/cas-add-host-mount.yaml

would using /dev/shm use double the amount of memory?




In Viya 3, we defaulted to /tmp/
In Viya 4, we initially defaulted to /tmp/ in the pod, so the ephemeral-storage, ie, the FS of the container.

so , somewhere in the container's own FS. (leading to /var/lib/docker)

what happens if you fill the cache.
pods run out of storage

out of temp and into emptydir.

 /    200GB
 /var/lib/docker/ images / containers FS, emptydir
 /nvme0    2TB


ln /nvme  /var/lib/docker/emptydir

nodepool 1-5  10

/     2 TB
/var/lib/docker


ephemeral storage is only EmptyDir (disk ones)

/mnt


/nvme0
/nvme1

/mnt/nvme0
/mnt/nvme1

what is the default?
what is the recommended changes we should make?

node affinity

normal-cas
    5 workers

weekendCAS
    60
