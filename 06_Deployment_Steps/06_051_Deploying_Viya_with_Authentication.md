![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploying Viya with Authentication

* [Intro](#intro)
* [Deploy the GELLDAP utility into the lab namespace](#deploy-the-gelldap-utility-into-the-lab-namespace)
* [Prep Steps](#prep-steps)
  * [Making backups of important file](#making-backups-of-important-file)
  * [GELLDAP sitedefault file](#gelldap-sitedefault-file)
  * [The Authentication information](#the-authentication-information)
  * [Update the Kustomization file](#update-the-kustomization-file)
    * [Manually, like in the field](#manually-like-in-the-field)
    * [Automatically, because we are in a lab](#automatically-because-we-are-in-a-lab)
* [Build Step](#build-step)
  * [Re-build the manifest file](#re-build-the-manifest-file)
* [Deploy steps](#deploy-steps)
  * [Re-Deploy the lab namespace](#re-deploy-the-lab-namespace)
* [Bounce some pods](#bounce-some-pods)
  * [Validate that the authentication works](#validate-that-the-authentication-works)
  * [Test that it works (manual)](#test-that-it-works-manual)
* [Navigation](#navigation)

## Intro

In the [previous deployment](01_Deploying_a_simple_environment.md), we did not do anything special about authentication, and therefore, the only usable user was **sasboot**.

We assume that you currently have a Viya deployment running in the lab namespace.
If that is not the case, execute the following command and wait for it complete before proceeding:

```sh
NS=lab
if kubectl get ns | grep -q "$NS\ " ; then
    echo "found $NS namespace. so, assuming you have Viya running in it";
else
    echo "$NS namespace does not exist. So, kicking off the accelerated deployment of it"
    bash ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/06_Deployment_Steps/06_031_Deploying_a_simple_environment.sh
fi

```

In this deployment, we will configure the authentication of the environment to work off of an OpenLDAP server, running in the same namespace as Viya.

## Deploy the GELLDAP utility into the lab namespace

1. This step has been highly automated to make your life easier. You're welcome!

1. The GELLDAP project is located [here](https://gelgitlab.race.sas.com/GEL/utilities/gelldap)

1. Clone the GELLDAP project into the project directory

    ```bash
    cd ~/project/
    git clone https://gelgitlab.race.sas.com/GEL/utilities/gelldap.git
    cd ~/project/gelldap/
    git fetch --all
    GELLDAP_BRANCH=master
    git reset --hard origin/${GELLDAP_BRANCH}

    ```

1. Deploy GELLDAP into the namespace (**do provide the namespace here**)

    ```bash

    cd ~/project/gelldap/
    kustomize build ./no_TLS/ | kubectl -n lab apply -f -

    ```

    You should see

    ```log
    configmap/gelldap-bootstrap-users created
    configmap/gelldap-memberof-overlay created
    service/gelldap-service created
    service/gelmail-service created
    deployment.apps/gelldap-server created
    deployment.apps/gelmail-server created

    ```

1. To confirm that the pod is running, running

    ```sh
    kubectl -n lab get all,cm -l app.kubernetes.io/part-of=gelldap
    ```

   should return the following:

    ```log
    NAME                                  READY   STATUS    RESTARTS   AGE
    pod/gelldap-server-6697fbb7b6-rs9vr   1/1     Running   0          19m

    NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
    service/gelldap-service   ClusterIP   10.43.89.154   <none>        389/TCP             19m
    service/gelmail-service   ClusterIP   10.43.0.180    <none>        1025/TCP,8025/TCP   19m

    NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
    deployment.apps/gelldap-server   1/1     1            1           19m

    NAME                                        DESIRED   CURRENT   READY   AGE
    replicaset.apps/gelldap-server-6697fbb7b6   1         1         1       19m

    NAME                                 DATA   AGE
    configmap/gelldap-bootstrap-users    1      19m
    configmap/gelldap-memberof-overlay   1      19m

    ```

1. To confirm that the service listens on port 389:

    ```bash
    # first, get the service IP:
    kubectl -n lab get svc -l app.kubernetes.io/part-of=gelldap,app=gelldap-service -o=custom-columns='IP:spec.clusterIP' --no-headers
    # store it in a variable:
    IP_GELLDAP=$(kubectl -n lab get svc -l app.kubernetes.io/part-of=gelldap,app=gelldap-service -o=custom-columns='IP:spec.clusterIP' --no-headers)
    # now curl it:
    curl -v ${IP_GELLDAP}:389

    ```

    You should see:

    ```log
    * About to connect() to 10.43.103.202 port 389 (#0)
    *   Trying 10.43.103.202...
    * Connected to 10.43.103.202 (10.43.103.202) port 389 (#0)
    > GET / HTTP/1.1
    > User-Agent: curl/7.29.0
    > Host: 10.43.103.202:389
    > Accept: */*
    >
    * Empty reply from server
    * Connection #0 to host 10.43.103.202 left intact
    curl: (52) Empty reply from server
    ```

1. The GELLDAP server comes with pre-written sitedefault and sssd information.

1. Let's copy the provided file in the proper location:

    ```bash
    cp ~/project/gelldap/no_TLS/gelldap-sitedefault.yaml \
       ~/project/deploy/lab/site-config/

    ```

1. These  two files will be referenced in the kustomization file in the later steps

## Prep Steps

### Making backups of important file

We will be modifying some files, so let's back them up first:

```bash
cd ~/project/deploy/lab
cp kustomization.yaml  kustomization.yaml.before_auth
cp site.yaml  site.yaml.before_auth
```

### GELLDAP sitedefault file

The file `gelldap-sitedefault.yaml` has been copied into your `site-config` folder already.

to review its content, run:

```bash
yq -C r  ~/project/deploy/lab/site-config/gelldap-sitedefault.yaml

```

<!--
 Volume Mount definitions

While the SSSD configmap defines the content of the `sssd.conf` file, we need to provide instructions to Kubernetes on how to mount that file and into which pods.

1. That ConfigMap needs to be added into the right location inside the CAS pod(s):

    ```sh
    bash -c "cat << EOF > ~/project/deploy/lab/site-config/cas-sssd-volume.yaml
    ---
    # SSSD config map
    apiVersion: builtin
    kind: PatchTransformer
    metadata:
      name: sssd-apply-all
    patch: |-
      - op: add
        path: /spec/controllerTemplate/spec/volumes/-
        value:
          name: sssd-config
          configMap:
            name: sas-sssd-config
            defaultMode: 420
            items:
            - key: SSSD_CONF
              mode: 384
              path: sssd.conf
      - op: add
        path: /spec/controllerTemplate/spec/containers/0/volumeMounts/-
        value:
          name: sssd-config
          mountPath: /sssd
    target:
      group: viya.sas.com
      kind: CASDeployment
      name: .*
      version: v1alpha1
    EOF"

    ```
 -->

<!--

1. And the same thing needs to be done in **compsrv** pod too:

    ```bash
    tee ~/project/deploy/lab/site-config/compsrv-sssd-volume.yaml > /dev/null <<EOF
    ---
    - op: add
      path: /spec/template/spec/volumes/-
      value:
        configMap:
          items:
            - key: SSSD_CONF
              mode: 384
              path: sssd.conf
          name: sas-sssd-config
        name: sssd-config
    - op: add
      path: /spec/template/spec/containers/1/volumeMounts/-
      value:
        name: sssd-config
        mountPath: /etc/sssd
    EOF

    ```
 -->

### The Authentication information

In Viya 3.X, the `sitedefault.yml` was used to "pre-load" content into Consul. It was used mostly for things like the Authentication Details (LDAP info) instead of having to enter them manually in the Environment Manager interface.

In Viya 4.X, the same use remains, even if for consistency, we use `yaml` as the extension instead of `yml`.

However, there is another thing at play here.

In Viya 3.X, you were supposed to configure SSSD on the Viya servers (CAS/Compute) so that the user IDs would be known. It was up to the customer to provide a valid `sssd.conf` file.

In Viya 4.X, whenever SSSD is required, the `sssd.conf` file is **automatically generated** based off of the content in Consul. Therefore, there should be no need to provide an `sssd.conf` file, as it will be automatically generated (via consul templates) and inserted into the pods that will need it.

If for some reason the generated `sssd.conf` file is inaccurate or insufficient, a customer could choose to override it, using Kubernetes ConfigMaps and Kubernetes Volumes.

### Update the Kustomization file

#### Manually, like in the field

1. Using your favorite text editor (or vi), open up the kustomization.yaml file. Or rather, you'll edit manually a copy of it, and then we'll make sure you did it well.

    ```sh
    cd ~/project/deploy/lab
    cp ./kustomization.yaml ./kustomization.yaml.manual
    code ~/project/deploy/lab/kustomization.yaml.manual
    # if VS Code does not open, you can >> use the Moba sFTP pane | right click | open with | {VS Code | text editor of your choice}
    ```

1. Locate the line that points to the `sitedefault.yaml` file and make sure that you make it point to `gelldap-sitedefault.yaml` instead. Make that change and save the file.

<!--
1. Also, we need to add a couple lines for the SSSD volume for CAS
1. First:

    the following line:

    ```sh
      - site-config/gelldap-sssd-configmap.yaml
    ```

    has to be added

    * in the `resources:` section
    * ideally at the bottom
    * indented properly (the dashes `-` have to line up)

1. Second:

    the line:

    ```sh
      - site-config/cas-sssd-volume.yaml
    ```

    has to be added

    * in the `transformers:` section
    * ideally at the bottom
    * indented properly (the dashes `-` have to line up)
 -->

#### Automatically, because we are in a lab

To make sure that you did not screw up the manual update of the file, you'll have to copy paste the blocks below to do the same thing in an automated fashion.

1. For the sitedefault:

    ```bash
    cd ~/project/deploy/lab
    cp ./kustomization.yaml ./kustomization.yaml.automatic

    ansible localhost \
    -m lineinfile \
    -a  "dest=~/project/deploy/lab/kustomization.yaml.automatic \
        regexp='^      - SITEDEFAULT_CONF' \
        line='      - SITEDEFAULT_CONF=site-config/gelldap-sitedefault.yaml' \
        state=present \
        backup=yes " \
        --diff

    ```

<!--
1. And for the automated way for the sssd part, we can use [yq](https://github.com/mikefarah/yq) instead:
    ```sh
    # first, remove the lines if they already exist in the file:
    sed -i '/-sssd-/d' ~/project/deploy/lab/kustomization.yaml.automatic

    # add the first line
    printf "
    - command: update
      path: resources[+]
      value: site-config/gelldap-sssd-configmap.yaml
    " | yq  -I 4 w -i -s - ~/project/deploy/lab/kustomization.yaml.automatic

    ## add the second line:
    printf "
    - command: update
      path: transformers[+]
      value: site-config/cas-sssd-volume.yaml
    " | yq -I 4 w -i -s - ~/project/deploy/lab/kustomization.yaml.automatic

    ```
 -->

1. At this point, you should compare the 2 files to make sure you manual changes are ok.

    ```sh
    cd ~/project/deploy/lab
    icdiff -WH kustomization.yaml.manual kustomization.yaml.automatic

    ```

1. They should be identical. The diff should not show any differences.

1. Just to be sure, let's use the automated one:

    ```bash
    cd ~/project/deploy/lab
    mv kustomization.yaml kustomization.yaml.orig
    cp kustomization.yaml.automatic kustomization.yaml

    ```

1. Now, let's review the changes you made do a diff to confirm the change was made:

    ```sh
    cd ~/project/deploy/lab
    icdiff -H  kustomization.yaml.before_auth kustomization.yaml

    ```

## Build Step

### Re-build the manifest file

1. Re-run the kustomize command to re-generate site.yaml:

    ```bash
    cd ~/project/deploy/lab
    kustomize build -o site.yaml

    ```

1. And now, confirm you see the expected changes and only those:

    ```sh
    cd ~/project/deploy/lab
    icdiff -H site.yaml.before_auth site.yaml

    ```

In this output, you should see an "unexpected change": not only did we add more content to the sitefault file, but the name of the configmap (`sas-consul-config-xxxxxxxx`) has been altered. This is normal, expected, and by design.

## Deploy steps

### Re-Deploy the lab namespace

1. And now, we apply the manifests

    ```bash

    kubectl -n lab apply  -f site.yaml --selector="sas.com/admin=cluster-wide"

    kubectl -n lab wait --for condition=established --timeout=60s -l "sas.com/admin=cluster-wide" crd

    kubectl -n lab apply  --selector="sas.com/admin=cluster-local" -f site.yaml --prune

    kubectl -n lab apply  --selector="sas.com/admin=namespace" -f site.yaml --prune

    ```

Because the name of the configmap for the sitedefault has been updated, the consul pods will be stopped and restarted so that it can integrate those updated values. This might trigger a rolling of some of the other pods.

## Bounce some pods

You should not have to bounce any pods. But in reality, things wont' work until you do.

In the future, a change such as this one should hopefully not require any manual intervention.

Currently, it seems that the environment needs a few pods to be bounced for all the authentication to work.

There are 2 ways to bounce pods.

1. First, you can just "delete" those pods, and kubernetes will restart them.

    ```sh
    kubectl -n lab -l app=sas-identities delete pods
    kubectl -n lab -l app=sas-logon-app delete pods
    kubectl -n lab delete pods -l app.kubernetes.io/name=sas-cas-server
    ```

1. However, that will provoke some downtime for those applications.

1. So an alternative is the Rollout command, which will first bring up a replacement, and only terminate the original pod once the replacement is up and running.

    ```bash
    kubectl -n lab  rollout restart deployment sas-identities
    kubectl -n lab  rollout restart deployment sas-logon-app
    # CAS itself does not support this model, so we delete the pods managed by it
    kubectl -n lab delete pods -l app.kubernetes.io/name=sas-cas-server
    ```



<!--
### If pods are pending.

If using a single machine RACE collection, you might want to stop the part you won't use, so it can fit.

```sh

source <( cat /opt/raceutils/.bootstrap.txt  )
source <( cat /opt/raceutils/.id.txt  )

if  [ "$collection_size" = "2"  ] ; then

## Scale down parts of the environment to save on resources
kubectl -n lab scale deployments --replicas=0 \
    compsrv                                        \
    sas-connect                                    \
    sas-connect-spawner                            \
    sas-natural-language-understanding             \
    sas-natural-language-generation                \
    sas-natural-language-conversations             \
    sas-esp-operator                               \
    sas-event-stream-manager-app                   \
    sas-event-stream-processing-metering-app       \
    sas-event-stream-processing-server-app         \
    sas-event-stream-processing-streamviewer-app   \
    sas-event-stream-processing-studio-app         \
    sas-microanalytic-score

## this might be too much though:
# kubectl -n lab scale deployments --replicas=0 \
#     sas-audit                                      \
#     sas-comments                                   \
#     sas-conversation-designer-app                  \
#     sas-data-mining-models                         \
#     sas-data-mining-project-settings               \
#     sas-data-mining-results                        \
#     sas-data-mining-services                       \
#     sas-data-quality-services                      \
#     sas-device-management                          \
#     sas-forecasting-comparison                     \
#     sas-forecasting-events                         \
#     sas-forecasting-exploration                    \
#     sas-forecasting-filters                        \
#     sas-forecasting-pipelines                      \
#     sas-forecasting-services                       \
#     sas-geo-enrichment                             \
#     sas-microanalytic-score                        \
#     sas-model-management                           \
#     sas-model-manager-app                          \
#     sas-model-publish                              \
#     sas-model-repository                           \
#     sas-model-studio                               \
#     sas-templates                                  \
#     sas-text-analytics                             \
#     sas-text-cas-data-management                   \
#     sas-text-categorization                        \
#     sas-text-concepts                              \
#     sas-text-parsing                               \
#     sas-text-sentiment                             \
#     sas-text-topics                                \
#     sas-topic-management                           \
#     sas-workflow                                   \
#     sas-workflow-manager-app                       \
#     sas-workflow-definition-history                \

fi

```
 -->

### Validate that the authentication works

1. You need to wait about 5 minutes before trying to log into the app as:

    * `u: sasadm`
    * `p: lnxsas`

1. Assume your Admin privileges when logging in

1. If you are not sure if the environment is ready, check it by running:

    ```bash
    gel_OKViya4 -n lab --wait -ps

    # or

    kubectl wait -n lab --for=condition=ready pod --selector='app.kubernetes.io/name=sas-readiness'  --timeout=2700s

    ```

### Test that it works (manual)

1. Open up the application

    ```bash
    cat ~/urls.md | grep Drive | grep tryit

    ```

1. Log in as `sastest1` (pw: `lnxsas`)
1. Go to Studio
1. Start a CAS session
 - if you have errors starting the CAS session, you could consider trying to load data via Data Explorer (Environment Manager), or you might do a hard restart of the web browser, or you could even consider re-running the rollout and CAS delete pods from the prior section

## Navigation

<!-- startnav -->
* [01 Introduction / 01 031 Booking a Lab Environment for the Workshop](/01_Introduction/01_031_Booking_a_Lab_Environment_for_the_Workshop.md)
* [01 Introduction / 01 032 Assess Readiness of Lab Environment](/01_Introduction/01_032_Assess_Readiness_of_Lab_Environment.md)
* [02 Kubernetes and Containers Fundamentals / 02 131 Learning about Namespaces](/02_Kubernetes_and_Containers_Fundamentals/02_131_Learning_about_Namespaces.md)
* [03 Viya 4 Software Specifics / 03 011 Looking at a Viya 4 environment with Visual Tools DEMO](/03_Viya_4_Software_Specifics/03_011_Looking_at_a_Viya_4_environment_with_Visual_Tools_DEMO.md)
* [03 Viya 4 Software Specifics / 03 031 Create your own Viya order](/03_Viya_4_Software_Specifics/03_031_Create_your_own_Viya_order.md)
* [04 Pre Requisites / 04 061 Pre Requisites automation with ARKCD](/04_Pre-Requisites/04_061_Pre-Requisites_automation_with_ARKCD.md)
* [05 Deployment tools / 05 121 Setup a Windows Client Machine](/05_Deployment_tools/05_121_Setup_a_Windows_Client_Machine.md)
* [06 Deployment Steps / 06 031 Deploying a simple environment](/06_Deployment_Steps/06_031_Deploying_a_simple_environment.md)
* [06 Deployment Steps / 06 051 Deploying Viya with Authentication](/06_Deployment_Steps/06_051_Deploying_Viya_with_Authentication.md)**<-- you are here**
* [06 Deployment Steps / 06 061 Deploying in a second namespace](/06_Deployment_Steps/06_061_Deploying_in_a_second_namespace.md)
* [06 Deployment Steps / 06 071 Removing Viya deployments](/06_Deployment_Steps/06_071_Removing_Viya_deployments.md)
* [06 Deployment Steps / 06 215 Deploying a programing only environment](/06_Deployment_Steps/06_215_Deploying_a_programing-only_environment.md)
* [07 Deployment Customizations / 07 051 Adding a local registry to k8s](/07_Deployment_Customizations/07_051_Adding_a_local_registry_to_k8s.md)
* [07 Deployment Customizations / 07 052 Using mirrormgr to populate the local registry](/07_Deployment_Customizations/07_052_Using_mirrormgr_to_populate_the_local_registry.md)
* [07 Deployment Customizations / 07 053 Deploy from local registry](/07_Deployment_Customizations/07_053_Deploy_from_local_registry.md)
* [11 Azure AKS Deployment / 11 011 Creating an AKS Cluster](/11_Azure_AKS_Deployment/11_011_Creating_an_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 012 Performing Prereqs in AKS](/11_Azure_AKS_Deployment/11_012_Performing_Prereqs_in_AKS.md)
* [11 Azure AKS Deployment / 11 013 Deploying Viya 4 on AKS](/11_Azure_AKS_Deployment/11_013_Deploying_Viya_4_on_AKS.md)
* [11 Azure AKS Deployment / 11 014 Deleting the AKS Cluster](/11_Azure_AKS_Deployment/11_014_Deleting_the_AKS_Cluster.md)
* [11 Azure AKS Deployment / 11 015 Fast track with cheatcodes](/11_Azure_AKS_Deployment/11_015_Fast_track_with_cheatcodes.md)
* [11 Azure AKS Deployment / 11 131 CAS Customizations](/11_Azure_AKS_Deployment/11_131_CAS_Customizations.md)
* [11 Azure AKS Deployment / 11 132 Install monitoring and logging](/11_Azure_AKS_Deployment/11_132_Install_monitoring_and_logging.md)
<!-- endnav -->

<!--
Waiting for it to be up
```bash
if  [ "$1" == "wait" ]
then
    time gel_OKViya4 -n lab --wait -ps
fi
```
-->
