![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

* [Prepare the Database Client files](#prepare-the-database-client-files)
* [Make sure you can contact the Database server](#make-sure-you-can-contact-the-database-server)
* [Reference Database Clients volume using Kustomize PatchTransformers files](#reference-database-clients-volume-using-kustomize-patchtransformers-files)
  * [Create PatchTransformers for CAS, sas-compute-job-config and sas-launcher-job-config pods](#create-patchtransformers-for-cas-sas-compute-job-config-and-sas-launcher-job-config-pods)
  * [Add the patchTransformers in the kustomize.yaml file](#add-the-patchtransformers-in-the-kustomizeyaml-file)
* [Configure sas-access.properties](#configure-sas-accessproperties)
  * [Prepare the sas-access content](#prepare-the-sas-access-content)
* [Edit the base kustomization.yaml file](#edit-the-base-kustomizationyaml-file)
* [Configure database Host resolution for the pods](#configure-database-host-resolution-for-the-pods)
  * [Prepare for defining HostAliases for SAS Viya using Kustomize PatchTransformers files](#prepare-for-defining-hostaliases-for-sas-viya-using-kustomize-patchtransformers-files)
  * [Update the base kustomization.yaml file](#update-the-base-kustomizationyaml-file)
* [Update and re-apply the manifests](#update-and-re-apply-the-manifests)
* [Test SAS Libraries and CASLIBs](#test-sas-libraries-and-caslibs)
* [Optional Test ORACLE Serial and multinode loading](#optional-test-oracle-serial-and-multinode-loading)

# Configure a SAS/ACCESS to Oracle

Reference :  <https://gitlab.sas.com/GEL/datamanagement/viya4/-/blob/master/configure-sas-access/configure_SAS_ACCESS_in_Viya_4.md>

Official WIP doc : <http://pubshelpcenter.unx.sas.com:8080/preview/?docsetId=rnddplyreadmes&docsetTarget=sas-access-config_examples_data-access_README.htm&docsetVersion=friday&locale=en>

## Prepare the Database Client files

The first step is to provision a Kubernetes Persistent Volume to store the database third-party libraries and configuration files that are required for your data sources.

In the RACE environment, our Kubernetes cluster is using NFS for the persistent storage.

* So we collect the files we need and place them in a directory on the NFS server, then we will export this directory as an NFS mount point for the Kuberbnetes Nodes.

    ```bash
    #create a directory on the NFS server (node01)
    sudo mkdir -p /opt/access-clients/oracle
    # make cloud-user owner
    sudo chown -R cloud-user:cloud-user /opt/access-clients
    # download the oracle CLI
    wget https://download.oracle.com/otn_software/linux/instantclient/19800/instantclient-basic-linux.x64-19.8.0.0.0dbru.zip
    mv instantclient-basic-linux.x64-19.8.0.0.0dbru.zip /opt/access-clients/oracle
    cd /opt/access-clients/oracle
    unzip instantclient-basic-linux.x64-19.8.0.0.0dbru.zip
    ```

* Then we need to export our access-clients directory
* On node1.race.sas.com, edit ```/etc/exports``` and add the following line:

    ```log
    /opt/access-clients   *(rw,sync,no_root_squash)
    ```

* Run the command below to do it automatically

    ```bash
    # add an shared dir
    sudo bash -c 'echo "/opt/access-clients   *(rw,sync,no_root_squash)" >> /etc/exports'
    ```

* Refresh the exports:

    ```bash
    # refresh NFS export
    sudo exportfs -a
    ```

_Note: in a Cloud deployment, you would likely use something like a file storage service for that._

## Make sure you can contact the Database server

* set the DB_IP variables as we will use it in our configuration.

    ```bash
    export DB_IP="10.96.8.2"
    echo "${DB_IP}    sasdb.race.sas.com" > /tmp/db_ip.txt
    ```

* Add the sasdb line in the /etc/hosts file

    ```bash
    # update /etc/hosts with db IP and hostname
    sudo bash -c 'cat /tmp/db_ip.txt >> /etc/hosts'
    ```

* Test the Oracle DB port

    ```bash
    #test Oracle connection
    nc -zv sasdb.race.sas.com 1521
    ```

* You should see something like:

    ```log
    Ncat: Version 7.50 ( https://nmap.org/ncat )
    Ncat: Connected to 10.96.8.2:1521.
    Ncat: 0 bytes sent, 0 bytes received in 0.01 seconds.
    ```

## Reference Database Clients volume using Kustomize PatchTransformers files


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
    ```bash
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
    ```bash
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

### Add the patchTransformers in the kustomize.yaml file

* Either manually add the following lines in the transformers section:

    ```yaml
    transformers:
    ...
    - site-config/data-access/data-mounts-cas.yaml
    - site-config/data-access/data-mounts-job.yaml
    ```

* Or execute this code for the new transformers references

    ```bash
    # backup just in case
    cp ~/project/deploy/gelenv-stable/kustomization.yaml ~/project/deploy/gelenv-stable/kustomization.yaml.backup
    # add transformers lines with yq
    yq write  -i ~/project/deploy/gelenv-stable/kustomization.yaml "transformers[+]" "site-config/data-access/data-mounts-cas.yaml"
    yq write  -i ~/project/deploy/gelenv-stable/kustomization.yaml "transformers[+]" "site-config/data-access/data-mounts-job.yaml"
    ```

## Configure sas-access.properties

### Prepare the sas-access content

* Create site-config/data-access folder

    ```bash
    mkdir -p ~/project/deploy/gelenv-stable/site-config/data-access
    ```

* Copy sample configuration files:

    ```bash
    cp ~/project/deploy/gelenv-stable/sas-bases/examples/data-access/*.yaml ~/project/deploy/gelenv-stable/site-config/data-access
    ```

    ```bash
    # copy example and set permissions
    cp ~/project/deploy/gelenv-stable/sas-bases/examples/data-access/sas-access.properties ~/project/deploy/gelenv-stable/site-config/data-access
    chmod u+w ~/project/deploy/gelenv-stable/site-config/data-access/sas-access.properties
    ```

* Edit it to adjust environment variables or run the code below to only insert the variables that we need.

    ```bash
    #Oracle example:
    echo "ORACLE=/access-clients/oracle/instantclient_19_8" > ~/project/deploy/gelenv-stable/site-config/data-access/sas-access.properties
    echo "ORACLE_HOME=/access-clients/oracle/instantclient_19_8" >> ~/project/deploy/gelenv-stable/site-config/data-access/sas-access.properties
    ```

## Edit the base kustomization.yaml file

* Either manually add the following section for the ConfigMap generator:

    ```yaml
    configMapGenerator:
    ...
    - name: sas-access-config
        behavior: merge
        envs:
        - site-config/data-access/sas-access.properties
    ```

* Or execute this code to add a ConfigMapGenerator section

    ```bash
    # use yq to update the document with and additional configmap
    printf "
    - command: update
      path: configMapGenerator[+]
      value:
        name: sas-access-config
        behavior: merge
        envs:
          - site-config/data-access/sas-access.properties
    " | yq -I 4 w -i -s - ~/project/deploy/gelenv-stable/kustomization.yaml
    ```

* Add the data access overlay file to the kustomization.yaml file

    ```bash
    # add the transformer line with yq for the data-env overlay
    yq write  -i ~/project/deploy/gelenv-stable/kustomization.yaml "transformers[+]" "sas-bases/overlays/data-access/data-env.yaml"
    ```

## Configure database Host resolution for the pods

The machine where the database resides might not be referenced in the DNS and thus might not be accessible through a logical name but rather using its IP address.

Adding an appropriate entry in /etc/hosts on each Kubernetes cluster node does not solve the problem.

To use logical names, host aliases can be defined directly at the container "spec" levele using Kustomize PatchTransformers.

### Prepare for defining HostAliases for SAS Viya using Kustomize PatchTransformers files

* Create the site-config/network directory

    ```bash
    mkdir -p ~/project/deploy/gelenv-stable/site-config/network
    ```

* Create the site-config/network/etc-hosts-cas.yaml file for CAS-related pods:

    ```yaml
    cat > ~/project/deploy/gelenv-stable/site-config/network/etc-hosts-cas.yaml << EOF
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
          - ip: "${DB_IP}"
            hostnames:
            - "sasdb.race.sas.com"
    target:
        kind: CASDeployment
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```

<!-- for cheatcode
    ```bash
    cat > ~/project/deploy/gelenv-stable/site-config/network/etc-hosts-cas.yaml << EOF
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
          - ip: "${DB_IP}"
            hostnames:
            - "sasdb.race.sas.com"
    target:
        kind: CASDeployment
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```
-->


* Create site-config/network/etc-hosts-job.yaml for sas-compute-job-config and sas-launcher-job-config pods:

    ```yaml
    cat > ~/project/deploy/gelenv-stable/site-config/network/etc-hosts-job.yaml << EOF
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
          - ip: "${DB_IP}"
            hostnames:
            - "sasdb.race.sas.com"
    target:
        kind: PodTemplate
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```

<!-- for cheatcode
    ```bash
    cat > ~/project/deploy/gelenv-stable/site-config/network/etc-hosts-job.yaml << EOF
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
          - ip: "${DB_IP}"
            hostnames:
            - "sasdb.race.sas.com"
    target:
        kind: PodTemplate
        annotationSelector: sas.com/sas-access-config=true
    EOF
    ```
-->

### Update the base kustomization.yaml file

* Either manually add the following lines in the transformers section:

    ```yaml
    transformers:
    ...
    - site-config/network/etc-hosts-cas.yaml
    - site-config/network/etc-hosts-job.yaml
    ```

* Or execute this code for the new transformers references

    ```bash
    yq write  -i ~/project/deploy/gelenv-stable/kustomization.yaml "transformers[+]" "site-config/network/etc-hosts-cas.yaml"
    yq write  -i ~/project/deploy/gelenv-stable/kustomization.yaml "transformers[+]" "site-config/network/etc-hosts-job.yaml"
    ```

## Update and re-apply the manifests

* Build site.yaml

    ```bash
    mv site.yaml site-backup.yaml
    cd ~/project/deploy/gelenv-stable
    kustomize build -o site.yaml
    ```

* Check the differences

    ```sh
    icdiff site-backup.yaml site.yaml
    ```

* Apply new site.yaml

    ```bash
    kubectl apply -n gelenv-stable -f site.yaml
    ```

* Restart CAS

    ```bash
    kubectl -n gelenv-stable delete pod --selector='app.kubernetes.io/managed-by=sas-cas-operator'
    ```

* Check the access client

    ```bash
    kubectl -n gelenv-stable exec -it sas-cas-server-default-worker-0 -- ls -al /access-clients
    ```

* Check the pod alias

    ```bash
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
    10.96.8.2     sasdb.race.sas.com
    ```

## Test SAS Libraries and CASLIBs

* Open SASStudio as sasadm (password is lnxsas) and run the following code, to make sure you can access the Oracle Database tables and load them into CAS.

    ```sh
    libname orahr oracle user="hr" password="SASdb33" path="//sasdb.race.sas.com:1521/xe" schema="HR" preserve_names=yes ;

    cas mysession ;

    /* be careful with the user name ! it has to be upper case*/
    caslib DM_ORAHR datasource=(srctype="oracle",user="HR",password="SASdb33",path="//sasdb.race.sas.com:1521/xe",
    schema="HR",numreadnodes=10) libref=DM_ORAHR global ;

    proc casutil ;
        list files incaslib="DM_ORAHR" ;
    quit ;

    cas mysession terminate ;
    ```

_Note: If you haven't set host aliases in the pod configuration, you will have to use names.sas.com to rely on the DNS resolution._

## Optional Test ORACLE Serial and multinode loading

* You can use the code below to test serial and multi-node loading.

    ```sh
    cas mysession ;

    /*****************/
    /* ORACLE SERIAL */
    /*****************/

    %let caslib=ORA ;

    proc cas ;
    table.dropcaslib / caslib="&caslib" quiet=true ;
    quit ;
    caslib &caslib description="Oracle database"
    datasource=(srctype="oracle",user="CASDM",password="saswin",path="//sasdb.race.sas.com:1521/xe",
    schema="CASDM",numreadnodes=1,numwritenodes=1) ;

    /* 1 - List files and tables */
    proc casutil ;
    list files incaslib="&caslib" ;
    list tables incaslib="&caslib" ;
    quit ;

    /* 2 - Create a CAS table */
    proc ds2 sessref=mySession ;
    thread th / overwrite=yes ;
        dcl int index_pk ;
        dcl varchar(32) text ;
        method init();
            do index_pk=1 to 1000 ;
                text=put(index_pk,z32.) ;
                output ;
            end ;
        end ;
    endthread ;
    data &caslib..SAMPLE_TO_BE_DELETED(overwrite=yes copies=0) ;
        dcl thread th t ;
        method run() ;
            set from t ;
        end ;
    enddata;
    run ;
    quit ;
    proc casutil ;
    list tables incaslib="&caslib" ;
    quit ;

    /* 3 - Test write-back to the database (requires write access) */
    proc casutil ;
    deletesource casdata="DB_TO_BE_DELETED" incaslib="&caslib" quiet ;
    save casdata="SAMPLE_TO_BE_DELETED" incaslib="&caslib" outcaslib="&caslib" casout="DB_TO_BE_DELETED" replace ;
    list files incaslib="&caslib" ;
    quit ;

    /* Test load of the database table */
    proc casutil ;
    droptable casdata="CAS_TO_BE_DELETED" incaslib="&caslib" quiet ;
    load casdata="DB_TO_BE_DELETED" incaslib="&caslib" outcaslib="&caslib" casout="CAS_TO_BE_DELETED" replace ;
    list tables incaslib="&caslib" ;
    quit ;

    /* 4 - Cleanup */
    proc casutil ;
    droptable casdata="SAMPLE_TO_BE_DELETED" incaslib="&caslib" quiet ;
    droptable casdata="th" incaslib="&caslib" quiet ;
    droptable casdata="CAS_TO_BE_DELETED" incaslib="&caslib" quiet ;
    deletesource casdata="DB_TO_BE_DELETED" incaslib="&caslib" quiet ;
    list tables incaslib="&caslib" ;
    list files incaslib="&caslib" ;
    quit ;

    /*********************/
    /* ORACLE MULTI-NODE */
    /*********************/

    /* - re-create the CASLIB by setting numreadnodes and numwritenodes accordingly */
    /* - re-run the same code, steps 1-2-3-4 */
    /* - setting those options to a higher number than the possible number of workers will display */
    /*   an interesting warning in the log showing the actual number of workers configured for multi-node */

    %let caslib=ORA ;

    proc cas ;
    table.dropcaslib / caslib="&caslib" quiet=true ;
    quit ;
    caslib &caslib  description="Oracle database"
    datasource=(srctype="oracle",user="CASDM",password="saswin",path="//sasdb.race.sas.com:1521/xe",
    schema="CASDM",numreadnodes=10,numwritenodes=10) ;

    /* - run steps 1-2-3-4 */
    ```
