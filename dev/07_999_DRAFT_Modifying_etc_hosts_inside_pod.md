![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Modifying /etc/hosts inside the pod(s)

* [stepwise approach](#stepwise-approach)
* [Issue](#issue)
  * [Intro](#intro)
* [Confirming the issue](#confirming-the-issue)
* [Fixing things in the manifest](#fixing-things-in-the-manifest)
* [Kustomize](#kustomize)
* [Re-deploy](#re-deploy)

## stepwise approach

1. identify issue
1. pass/fail test
1. fixing it in manifest
1. fixing it through kustomize

## Issue

### Intro

What if your pod cannot reach a resource because it's not properly defined in the DNS?

In a BareOS environment, the Linux admin might just update the `/etc/hosts` file on the server(s) and be done with that.

But that won't helps us here.

Let's imagine that we have a resource (say a database) called `mydb`, and that its ip is `99.99.99.99`.

## Confirming the issue

1. Make sure we have a running Viya pod

    ```bash
    kubectl get pods
    ```

1. Choose a pod to test with:

    ```bash
    CAS_CONTROLLER=$(kubectl get pod -l casoperator.sas.com/node-type=controller --no-headers |  awk  '{  print  $1  }' )
    echo ${CAS_CONTROLLER}

    ## ping won't work
    kubectl exec -it ${CAS_CONTROLLER}  -- ping mydb

    #but curl might
    kubectl exec -it ${CAS_CONTROLLER}  -- curl -v mydb:1234

    kubectl exec -it ${CAS_CONTROLLER}  -- cat /etc/hosts
    ```

## Fixing things in the manifest

The kubernetes concept at play here is called a [HostAlias](https://kubernetes.io/docs/concepts/services-networking/add-entries-to-pod-etc-hosts-with-host-aliases/).

Therefore, we know that our pods would need to look like:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostaliases-pod
spec:
  hostAliases:
  - ip: "99.99.99.99"
    hostnames:
    - "mydb"
  - ip: "98.98.98.98"
    hostnames:
    - "anotherdb"
    - "anotherdb.sas.com"
```

Now, we are not updating the `site.yaml` manually, so we'll have to coax Kustomize into doing this for us.

## Kustomize

First, we will create a a PatchTransformer called `host_alias_cas.yaml`

```bash
cd ~/project/deploy/lab

tee  ./site-config/host_alias_cas.yaml > /dev/null << "EOF"
apiVersion: builtin
kind: PatchTransformer
metadata:
  name: etc-hosts-cas
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/hostAliases
    value:
      - ip: "99.99.99.99"
        hostnames:
          - "mydb"
target:
  kind: CASDeployment
  annotationSelector: sas.com/sas-access-config=true

EOF

```

And once that is done, add the following line to your transformer section in kustomization.yaml:

```yaml
transformers:
  - site-config/host_alias_cas.yaml
```

Now re-build a newer site.yaml and compare:

```bash

mv site.yaml site_without_etc_hosts.yaml

kustomize build -o site.yaml

icdiff site_without_etc_hosts.yaml site.yaml

```

the icdiff should show:

```log
./site_without_etc_hosts.yaml                                    site.yaml
        volumeMounts:                                                    volumeMounts:
        - mountPath: /sasviyabackup                                      - mountPath: /sasviyabackup
          name: backup                                                     name: backup
        - mountPath: /cas/data                                           - mountPath: /cas/data
          name: cas-default-data-volume                                    name: cas-default-data-volume
                                                                       hostAliases:
                                                                       - hostnames:
                                                                         - mydb
                                                                         ip: 99.99.99.99
      imagePullSecrets:                                                imagePullSecrets:
      - name: sas-image-pull-secrets-4484b485hk                        - name: sas-image-pull-secrets-4484b485hk
      securityContext:                                                 securityContext:
        fsGroup: 1001                                                    fsGroup: 1001
      serviceAccountName: sas-cas-server                               serviceAccountName: sas-cas-server
```

## Re-deploy

```bash
cd ~/project/deploy/lab/
kubectl apply -f site.yaml

```

bounce the CAS controller:

```bash
kubectl delete pod -l casoperator.sas.com/node-type=controller

```

re-test the same [as earlier](#confirming-the-issue) to confirm things now work:


