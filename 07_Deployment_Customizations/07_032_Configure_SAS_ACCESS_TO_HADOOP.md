![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Configure a SAS/ACCESS to Hadoop

* [Configure the connection to the remote Hadoop cluster (F2F only)](#configure-the-connection-to-the-remote-hadoop-cluster-f2f-only)
* [Configure the Hive connection account](#configure-the-hive-connection-account)
* [Run the hadoop-tracer on the remote Hadoop cluster](#run-the-hadoop-tracer-on-the-remote-hadoop-cluster)
  * [Use HadoopTracer to collect the Hadoop jar files](#use-hadooptracer-to-collect-the-hadoop-jar-files)
  * [Determine if the hadooptracer run was Successful](#determine-if-the-hadooptracer-run-was-successful)
* [Configure the Persistent Storage for our Hadoop client files](#configure-the-persistent-storage-for-our-hadoop-client-files)
* [Reference Hadoop Clients volume using Kustomize PatchTransformers files](#reference-hadoop-clients-volume-using-kustomize-patchtransformers-files)
  * [Create PatchTransformers for CAS, sas-compute-job-config and sas-launcher-job-config pods](#create-patchtransformers-for-cas-sas-compute-job-config-and-sas-launcher-job-config-pods)
  * [Add the patchTransformers in the kustomization.yaml file](#add-the-patchtransformers-in-the-kustomizationyaml-file)
* [Configure sas-access.properties](#configure-sas-accessproperties)
* [Configure database Host resolution for the pods](#configure-database-host-resolution-for-the-pods)
  * [Prepare for defining HostAliases for SAS Viya using Kustomize PatchTransformers files](#prepare-for-defining-hostaliases-for-sas-viya-using-kustomize-patchtransformers-files)
  * [Update the base kustomization.yaml file](#update-the-base-kustomizationyaml-file)
* [Update and re-apply the manifests](#update-and-re-apply-the-manifests)
* [Test SAS Libraries and CASLIBs](#test-sas-libraries-and-caslibs)

## Configure the connection to the remote Hadoop cluster (F2F only)

First thing first, our CAS controller must be able to contact the remote Hive server.

As there is no remote hadoop cluster as part of this collection, in this particular Hands-on we use a common Hadoop collection which is part of the VLE/workshop standby collection):

<!-- * Hive Server IP: < **10.96.8.245** or ask the instructor> (original long term reservation without EP)-->
<!-- * Hive Server IP: < **10.96.17.182** or ask the instructor
* Hive Server Hostname: sashdp02.race.sas.com
<!-- * HDFS NameNode IP: **10.96.5.184** (original long term reservation without EP)
* HDFS NameNode IP: **10.96.11.106**
* HDFS NameNode Hostname: sashdp01.race.sas.com
* Ambari URL: <http://10.96.5.184:8080/>
 -->
* Let's set environment variables for our Hadoop servers IP addresses (ask the instructor to check if the IP addresses are correct):

    ```sh
    export HIVE_IP="10.96.17.182"
    export HDFS_IP="10.96.11.106"
    ```

Check the IP addresses with the instructor as they are subject to change.

With this information, update ```/etc/hosts``` on our Ansible controller:

* Open the file with your favorite text editor:

    ```sh
    sudo vi /etc/hosts
    ```

* Then add the 2 lines below at the end of the file.

    ```log
    ${HIVE_IP} sashdp02.race.sas.com sashdp02
    ${HDFS_IP} sashdp01.race.sas.com sashdp01
    ```

* You can also do it automatically running this command :

    ```sh
    ansible localhost -m lineinfile -a "dest=/etc/hosts line='${HIVE_IP} sashdp02.race.sas.com sashdp02'" -b --diff
    ansible localhost -m lineinfile -a "dest=/etc/hosts line='${HDFS_IP} sashdp01.race.sas.com sashdp01'" -b --diff
    ```

* Ensure that you can "ssh" to this machine, then exit:

    ```sh
    ssh sashdp01.race.sas.com
    ```

* When prompted, type "y", then you should see :

    ```log
    [cloud-user@rext03-0182 ~]$ ssh sashdp01.race.sas.com
    The authenticity of host 'sashdp01.race.sas.com (10.96.11.106)' can't be established.
    ECDSA key fingerprint is SHA256:U0grULXFL26w+xOoL3+c5/4OsgpMOJz/dcbsvrcd6EQ.
    ECDSA key fingerprint is MD5:73:df:44:4d:a3:28:e3:6f:76:de:ce:be:4f:e3:4e:aa.
    Are you sure you want to continue connecting (yes/no)? yes
    Warning: Permanently added 'sashdp01.race.sas.com,10.96.11.106' (ECDSA) to the list of known hosts.
    Last login: Tue Sep 22 09:40:16 2020 from 172.16.58.33
    ```

    **Then don't forget to type ```exit``` to log out.**

* Test the Hive port

    ```sh
    #test Hive connection
    nc -zv ${HIVE_IP} 10000
    ```

* You should see something like:

    ```log
    Ncat: Version 7.50 ( https://nmap.org/ncat )
    Ncat: Connected to 10.96.17.182:10000.
    Ncat: 0 bytes sent, 0 bytes received in 0.03 seconds.
    ```

## Configure the Hive connection account

Then, to use the hadoop tracer playbook to collect the config xml and JARs files, we need an account:

1. That can be used to SSH from the ansible controller to the Hive server (without providing a password)

1. With a home directory in HDFS with write access

here, we will use the ```cloud-user``` account to run the hadoop tracer on the remote Hive machine.

## Run the hadoop-tracer on the remote Hadoop cluster

We assume that all the checks have been done on the Hadoop side to run the tool that will extract the required configuration and libraries (Python, strace, and wget installed, HDFS Home folder existing for the account running hadoop tracer, Hive is running, etc...).

Now, we have to create a copy of the inventory file to add the Hadoop cluster machine to the list of target references at the beginning of the file.

Reference : <http://pubshelpcenter.unx.sas.com:8080/test/?cdcId=itopscdc&cdcVersion=v_006&docsetId=dplyml0phy0dkr&docsetTarget=n1qi7huxqdeiq6n1rvcmsue5pevj.htm&locale=en>

### Use HadoopTracer to collect the Hadoop jar files

**Important : All the instructions in this section have to be executed on the remote Hadoop cluster.**

The Hadoop tracer script is included with SAS/ACCESS Interface to Hadoop and SAS In-Database Technologies for Hadoop.

* Connect to sashdp01 and create a temporary folder

    ```sh
    ssh sashdp01.race.sas.com
    ```

    ```sh
    # we use the EPOCH datetime to ensure each attendee is working inside its own temporary folder
    EPOCHDATENOW=$(date +'%s')
    echo $EPOCHDATENOW
    mkdir /tmp/htracer.${EPOCHDATENOW}
    ```

* Download the hadooptracer.zip file from the following FTP site to the directory that you created: ftp.sas.com/techsup/download/blind/access/hadooptracer.zip

    ```sh
    curl http://ftp.sas.com/techsup/download/blind/access/hadooptracer.zip -o /tmp/htracer.${EPOCHDATENOW}/hadooptracer.zip
    cd /tmp/htracer.${EPOCHDATENOW}
    unzip hadooptracer.zip
    ```

* Change permissions on the hadooptracer_py file to include the Execute permission:

    ```sh
    chmod 755 ./hadooptracer_py
    ```

* Run the hadooptracer

    ```sh
    time python ./hadooptracer_py --filterby=latest --postprocess --jsonfile ./driver.json -b /tmp/htracer.${EPOCHDATENOW}/
    exit
    ```

You may notice some errors...

![hadooptracer errors](img/2020-10-09-13-16-12.png)

But the most important is to know if the jar files and configuration have been extracted and placed in the /tmp folders.

**Extract from the official documentation :**

_Most errors with the Hadoop tracer script stem from improper usage or an incorrect cluster configuration. If there are a problems with the Hadoop cluster, they will typically show up in the stdout of the Hadoop tracer script in the form of Java traceback information._

_Another common problem occurs when users try to run the Hadoop tracer script on a cluster node that doesn't have Hadoop/Hive/HDFS/Yarn/Pig/etc in an available PATH. For example,_

```log
2020-04-07 12:16:51,036 hadooptracer [ERROR] pig is not found in the $PATH
```

_Inspect the hadooptracer.log file, located in "/tmp" by default, and use the rest of this troubleshooting section to resolve common issues. Some error messages in the console output for hadooptracer_py are normal and do not necessarily indicate a problem with the JAR and configuration file collection process._

_However, if the files are not collected as expected or if you experience problems connecting to Hadoop with the collected files, contact SAS Technical Support and include the hadooptracer.log and the hadooptracer.json files._

### Determine if the hadooptracer run was Successful

* Run this command to check it something was extracted

    ```sh
    ls -l /tmp/htracer.${EPOCHDATENOW}
    ```

* You should see :

    ```log
    total 8304
    -rw-r--r--. 1 cloud-user cloud-user 4264249 Oct  9 10:09 hadooptracer.json
    -rw-r--r--. 1 cloud-user cloud-user 4161268 Oct  9 10:09 hadooptracer.log
    -rw-r--r--. 1 cloud-user cloud-user   48576 Oct  9 06:39 hadooptracer.zip
    drwxr-xr-x. 4 cloud-user cloud-user   16384 Oct  9 10:09 jars
    drwxr-xr-x. 2 cloud-user cloud-user    4096 Oct  9 10:09 sitexmls
    ```

* Ensure that the required Hadoop JAR files are collected from the Hadoop cluster and placed in the ./jars directory.

    ```sh
    ls -l /tmp/htracer.${EPOCHDATENOW}/jars
    ```

* Ensure that the required Hadoop configuration files are collected from the Hadoop cluster and placed in ./confs directory.

    ```sh
    ls -l /tmp/htracer.${EPOCHDATENOW}/confs
    ```

* Now exit from sashdp01 and come back to your session on sasnode01.

    ```sh
    exit
    ```

## Configure the Persistent Storage for our Hadoop client files

We need to provision a Kubernetes Persistent Volume to store the database third-party libraries and configuration files that are required for your data sources.
In the RACE environment, our Kubernetes cluster is using NFS for the persistent storage.

* Now that we have collected the files we need and place them in a directory on the NFS server, then we will export this directory as an NFS mount point for the Kuberbnetes Nodes.

    ```sh
    #create a directory on the NFS server (node01)
    sudo mkdir -p /opt/access-clients/hadoop
    # make cloud-user owner
    sudo chown -R cloud-user:cloud-user /opt/access-clients

* Get the Hadoop jars and configuration folders from sashdp01

    ```sh
    scp -r cloud-user@sashdp01:/tmp/jars /opt/access-clients/hadoop
    scp -r cloud-user@sashdp01:/tmp/sitexmls /opt/access-clients/hadoop
    ```

_Note: here we copy the foders in "/tmp" that should be the same as the ones your created in your own directory "/tmp/htracer{EPOCH}"._

```If you have already completed the [Configure SAS ACCESS engine](/07_Deployment_Customizations/07_010_Configure_SAS_ACCESS_Engine.md) hands-on, you can skip the next steps this section```

* Then we need to export our access-clients directory
* On node1.race.sas.com, edit ```/etc/exports``` and add the following line:

    ```log
    /opt/access-clients   *(rw,sync,no_root_squash)
    ```

* Run the command below to do it automatically

    ```sh
    # add an shared dir
    ansible localhost -m lineinfile -a "dest=/etc/exports line='/opt/access-clients   *(rw,sync,no_root_squash)'" -b --diff
    ```

* Refresh the exports:

    ```sh
    # refresh NFS export
    sudo exportfs -a
    ```

_Note: in a Cloud deployment, you would likely use something like a file storage service for that._

## Reference Hadoop Clients volume using Kustomize PatchTransformers files

```If you have already completed the [Configure SAS ACCESS engine](/07_Deployment_Customizations/07_010_Configure_SAS_ACCESS_Engine.md) hands-on, skip the next steps this section and go directly the next [section](#configure-sas-accessproperties)```

* Create site-config/data-access

    ```sh
    mkdir -p ~/project/deploy/gelenv-stable/site-config/data-access
    ```

* Copy sample configuration files:

    ```sh
    cp ~/project/deploy/gelenv-stable/sas-bases/examples/data-access/*.yaml ~/project/deploy/gelenv-stable/site-config/data-access
    ```

### Create PatchTransformers for CAS, sas-compute-job-config and sas-launcher-job-config pods

* Create a PatchTransformer in site-config/data-access/data-mounts-cas.yaml

    ```yaml
    cat > ~/project/deploy/gelenv-stable/site-config/data-access/data-mounts-cas.yaml << EOF
    # General example for adding mounts to CAS workers
    # PatchTransformer
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
        name: data-mounts-cas
    patch: |- ## NFS path example - kubernetes will mount these for you
      - op: add
        path: /spec/controllerTemplate/spec/containers/0/volumeMounts/-
        value:
            name: db-client-access
            mountPath: "/access-clients"
      - op: add
        path: /spec/controllerTemplate/spec/volumes/-
        value:
            name: db-client-access
            nfs:
                path: /opt/access-clients
                server: intnode01.race.sas.com
    target:
        kind: CASDeployment
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```

<!-- for cheatcode
    ```sh
    cat > ~/project/deploy/gelenv-stable/site-config/data-access/data-mounts-cas.yaml << EOF
    # General example for adding mounts to CAS workers
    # PatchTransformer
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
        name: data-mounts-cas
    patch: |- ## NFS path example - kubernetes will mount these for you
      - op: add
        path: /spec/controllerTemplate/spec/containers/0/volumeMounts/-
        value:
            name: db-client-access
            mountPath: "/access-clients"
      - op: add
        path: /spec/controllerTemplate/spec/volumes/-
        value:
            name: db-client-access
            nfs:
                path: /opt/access-clients
                server: intnode01.race.sas.com
    target:
        kind: CASDeployment
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```
-->

* Create a PatchTransformer in site-config/data-access/data-mounts-job.yaml

    ```yaml
    cat > ~/project/deploy/gelenv-stable/site-config/data-access/data-mounts-job.yaml << EOF
    # General example for adding mounts to SAS containers with a
    # PatchTransformer
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
        name: data-mounts-job
    patch: |- ## NFS path example - kubernetes will mount these for you
      - op: add
        path: /template/spec/containers/0/volumeMounts/-
        value:
            name: db-client-access
            mountPath: "/access-clients"
      - op: add
        path: /template/spec/volumes/-
        value:
            name: db-client-access
            nfs:
                path: /opt/access-clients
                server: intnode01.race.sas.com
    target:
        kind: PodTemplate
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```

<!-- for cheatcode
    ```sh
    cat > ~/project/deploy/gelenv-stable/site-config/data-access/data-mounts-job.yaml << EOF
    # General example for adding mounts to SAS containers with a
    # PatchTransformer
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
        name: data-mounts-job
    patch: |- ## NFS path example - kubernetes will mount these for you
      - op: add
        path: /template/spec/containers/0/volumeMounts/-
        value:
            name: db-client-access
            mountPath: "/access-clients"
      - op: add
        path: /template/spec/volumes/-
        value:
            name: db-client-access
            nfs:
                path: /opt/access-clients
                server: intnode01.race.sas.com
    target:
        kind: PodTemplate
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```
-->

### Add the patchTransformers in the kustomization.yaml file

* Either manually add the following lines in the transformers section:

    ```yaml
    transformers:
    ...
    - site-config/data-access/data-mounts-cas.yaml
    - site-config/data-access/data-mounts-job.yaml
    ```

* Or execute this code for the new transformers references

    ```sh
    # backup just in case
    cp ~/project/deploy/gelenv-stable/kustomization.yaml ~/project/deploy/gelenv-stable/kustomization.yaml.backup
    # add transformers lines with yq
    yq write  -i ~/project/deploy/gelenv-stable/kustomization.yaml "transformers[+]" "site-config/data-access/data-mounts-cas.yaml"
    yq write  -i ~/project/deploy/gelenv-stable/kustomization.yaml "transformers[+]" "site-config/data-access/data-mounts-job.yaml"
    ```

## Configure sas-access.properties

* For SAS/ACCESS to HADOOP, SAS does not recommend setting these as environment variables within your sas-access.properties file, as they would then be used for any connections from your Viya cluster.
* Instead, within your SAS program, we will use:

    ```sh
    options set=SAS_HADOOP_JAR_PATH=$(PATH_TO_HADOOP_JARs);
    options set=SAS_HADOOP_CONFIG_PATH=$(PATH_TO_HADOOP_CONFIG);
    ```

## Configure database Host resolution for the pods

The machine where the Hive server resides might not be referenced in the DNS and thus might not be accessible through a logical name but rather using its IP address.

Adding an appropriate entry in /etc/hosts on each Kubernetes cluster node does not solve the problem.

To use logical names, host aliases can be defined directly at the container "spec" level using Kustomize PatchTransformers.

### Prepare for defining HostAliases for SAS Viya using Kustomize PatchTransformers files

* Create the site-config/network directory

    ```sh
    mkdir -p ~/project/deploy/gelenv-stable/site-config/network
    ```

* Make sure the environment variable for the Hive IP address is still there

    ```sh
    echo ${HIVE_IP}
    echo ${HDFS_IP}
    ```

* Create the site-config/network/etc-hosts-cas.yaml file for CAS-related pods:

    ```yaml
    cat > ~/project/deploy/gelenv-stable/site-config/network/etc-hosts-cas-for-hive.yaml << EOF
    # General example for adding hosts to CAS workers
    # PatchTransformer
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
        name: etc-hosts-cas
    patch: |-
      - op: add
        path: /spec/controllerTemplate/spec/hostAliases
        value:
          - ip: "${HIVE_IP}"
            hostnames:
            - "sashdp02.race.sas.com"
          - ip: "${HDFS_IP}"
            hostnames:
            - "sashdp01.race.sas.com"
    target:
        kind: CASDeployment
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```

<!-- for cheatcode
    ```sh
    cat > ~/project/deploy/gelenv-stable/site-config/network/etc-hosts-cas-for-hive.yaml << EOF
    # General example for adding hosts to CAS workers
    # PatchTransformer
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
        name: etc-hosts-cas
    patch: |-
      - op: add
        path: /spec/controllerTemplate/spec/hostAliases
        value:
          - ip: "${HIVE_IP}"
            hostnames:
            - "sashdp02.race.sas.com"
          - ip: "${HDFS_IP}"
            hostnames:
            - "sashdp01.race.sas.com"
    target:
        kind: CASDeployment
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```
-->

* Create site-config/network/etc-hosts-job.yaml for sas-compute-job-config and sas-launcher-job-config pods:

    ```yaml
    cat > ~/project/deploy/gelenv-stable/site-config/network/etc-hosts-job-for-hive.yaml << EOF
    # General example for adding hosts to SAS containers with a
    # PatchTransformer
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
        name: etc-hosts-job
    patch: |-
      - op: add
        path: /template/spec/hostAliases
        value:
          - ip: "${HIVE_IP}"
            hostnames:
            - "sashdp02.race.sas.com"
          - ip: "${HDFS_IP}"
            hostnames:
            - "sashdp01.race.sas.com"
    target:
        kind: PodTemplate
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```

<!-- for cheatcode
    ```sh
    cat > ~/project/deploy/gelenv-stable/site-config/network/etc-hosts-job-for-hive.yaml << EOF
    # General example for adding hosts to SAS containers with a
    # PatchTransformer
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
        name: etc-hosts-job
    patch: |-
      - op: add
        path: /template/spec/hostAliases
        value:
          - ip: "${HIVE_IP}"
            hostnames:
            - "sashdp02.race.sas.com"
          - ip: "${HDFS_IP}"
            hostnames:
            - "sashdp01.race.sas.com"
    target:
        kind: PodTemplate
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```
-->

<!-- _Note : If you have already completed the [Configure SAS ACCESS engine](/07_Deployment_Customizations/07_010_Configure_SAS_ACCESS_Engine.md) hands-on, be aware that by running the above commands we remove the Oracle DB reference in the pods_ -->

### Update the base kustomization.yaml file

* Either manually add the following lines in the transformers section:

    ```yaml
    transformers:
    ...
    - site-config/network/etc-hosts-cas-for-hive.yaml
    - site-config/network/etc-hosts-job-for-hive.yaml
    ```

* Or execute this code for the new transformers references

    ```sh
    yq write  -i ~/project/deploy/gelenv-stable/kustomization.yaml "transformers[+]" "site-config/network/etc-hosts-cas-for-hive.yaml"
    yq write  -i ~/project/deploy/gelenv-stable/kustomization.yaml "transformers[+]" "site-config/network/etc-hosts-job-for-hive.yaml"
    ```

## Update and re-apply the manifests

* Build site.yaml

    ```sh
    cd ~/project/deploy/gelenv-stable/
    mv site.yaml site-backup.yaml
    kustomize build -o site.yaml
    ```

* Check the differences

    ```sh
    icdiff site-backup.yaml site.yaml
    ```

* Apply new site.yaml

    ```sh
    kubectl apply -n gelenv-stable -f site.yaml
    ```

* Restart CAS

    ```sh
    kubectl -n gelenv-stable delete pod --selector='app.kubernetes.io/managed-by=sas-cas-operator'
    ```

* Restart Ccmpute et launcher

    ```sh
    kubectl -n gelenv-stable delete pod --selector='app=sas-compute'
    kubectl -n gelenv-stable delete pod --selector='app=sas-launcher'
    ```

* Make sure they have restarted

    ```sh
    kubectl get po --sort-by=.status.startTime -n gelenv-stable
    ```

* Check the access client

    ```sh
    kubectl -n gelenv-stable exec -it sas-cas-server-default-worker-0 -- ls -al /access-clients/hadoop
    ```

* Check the pod alias

    ```sh
    kubectl -n gelenv-stable exec -it sas-cas-server-default-worker-0 -- cat /etc/hosts
    ```

* You should see something like :

    ```log
    Defaulting container name to cas.
    Use 'kubectl describe pod/sas-cas-server-default-worker-0 -n gelenv-stable' to see all of the containers in this pod.
    # Kubernetes-managed hosts file.
    127.0.0.1       localhost
    ::1     localhost ip6-localhost ip6-loopback
    fe00::0 ip6-localnet
    fe00::0 ip6-mcastprefix
    fe00::1 ip6-allnodes
    fe00::2 ip6-allrouters
    10.42.0.96      worker-0.sas-cas-server-default.gelenv-stable.svc.cluster.local worker-0

    # Entries added by HostAliases.
    10.96.17.182     sashdp02.race.sas.com
    ```

## Test SAS Libraries and CASLIBs

* Open SASStudio and run the following code, to make sure you can access the Oracle Database tables and load them into CAS.

    ```sh
    options set=SAS_HADOOP_JAR_PATH="/access-clients/hadoop/jars";
    options set=SAS_HADOOP_CONFIG_PATH="/access-clients/hadoop/sitexmls";

    /* Test the libname engine */
    libname hivelib hadoop user=hive server="sashdp02.race.sas.com";

    /*delete the baseball table in case it exists*/
    proc datasets lib=hivelib;
        delete baseball;
    run;
    quit;

    /* create the baseball table */
    /*access to sashdp01 (HDFS NN) is required to do that*/
    data hivelib.baseball;
        set sashelp.baseball ;
    run;

    /* Test the caslib */
    cas mysession sessopts=(metrics=true) ;

    /*declare the Hive caslib*/
    *caslib cashive clear;
    caslib cashive datasource=(srctype="hadoop",server="sashdp02.race.sas.com",
    username="hive",
    hadoopconfigdir="/access-clients/hadoop/sitexmls",
    hadoopjarpath="/access-clients/hadoop/jars");

    /*show the caslib in SAS Studio*/
    libname cashive cas caslib="cashive";

    /*list the Hive tables and load one Hive table in CAS*/
    proc casutil;
    list files incaslib="cashive";
    list tables incaslib="cashive";
    quit;
    proc casutil;
    load casdata="baseball" casout="baseball" outcaslib="cashive";
    contents casdata="baseball" incaslib="cashive"; /* show contents of the table in cas */
    quit ;
    cas mysession terminate;
    ```
