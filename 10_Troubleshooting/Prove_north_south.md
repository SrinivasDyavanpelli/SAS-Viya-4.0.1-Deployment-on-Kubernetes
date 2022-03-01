![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# How to prove/disprove that  North-South is still in play

## summary

Normally, when Viya 4 pieces talk to each other, they should use the internal names provided as Kubernetes Services. (East-West).

If instead they talk to each other using the Ingress Name, the traffic leaves the cluster and comes back in through the front door. (North-South).

East-West is better than North-South.

If you have North-South pieces, your firewall needs to be configured to "let your cluster talk to itself" which is counter-intuitive.

## How to demonstrate

If you don't have an easy way to do that in a firewall, you can fake it by blocking the ingress in the pods.

## an attempt

Generate this file:


```bash

NS=gelenv-stable
kubectl -n ${NS} get ing -o custom-columns='host:spec.rules[*].host' --no-headers

ING_HOST=$(kubectl -n ${NS} get ing -o custom-columns='host:spec.rules[*].host' --no-headers | sort -u)

tee  ~/project/deploy/gelenv-stable/site-config/block_ing.yaml > /dev/null << EOF
---
apiVersion: builtin
kind: PatchTransformer
target:
  kind: CASDeployment
metadata:
  name: etc-hosts-cas
patch: |-
  - op: add
    path: /spec/controllerTemplate/spec/hostAliases
    value:
      - ip: "9.9.9.9"
        hostnames:
          - "${ING_HOST}"
---
apiVersion: builtin
kind: PatchTransformer
target:
  kind: DaemonSet
metadata:
  name: etc-hosts-ds
patch: |-
  - op: add
    path: /spec/template/spec/hostAliases
    value:
      - ip: "9.9.9.9"
        hostnames:
          - "${ING_HOST}"
---
apiVersion: builtin
kind: PatchTransformer
target:
  kind: Deployment
metadata:
  name: etc-hosts-deployment
patch: |-
  - op: add
    path: /spec/template/spec/hostAliases
    value:
      - ip: "9.9.9.9"
        hostnames:
          - "${ING_HOST}"
---
apiVersion: builtin
kind: PatchTransformer
target:
  kind: PodTemplate
metadata:
  name: etc-hosts-job
patch: |-
  - op: add
    path: /template/spec/hostAliases
    value:
      - ip: "9.9.9.9"
        hostnames:
          - "gelenv-stable.rext03-0063.race.sas.com"
---
apiVersion: builtin
kind: PatchTransformer
target:
  kind: StatefulSet
metadata:
  name: etc-hosts-statefulset
patch: |-
  - op: add
    path: /spec/template/spec/hostAliases
    value:
      - ip: "9.9.9.9"
        hostnames:
          - "${ING_HOST}"
---
apiVersion: builtin
kind: PatchTransformer
target:
  kind: CronJob
metadata:
  name: etc-hosts-cj
patch: |-
  - op: add
    path: /spec/jobTemplate/spec/template/spec/hostAliases
    value:
      - ip: "9.9.9.9"
        hostnames:
          - "${ING_HOST}"

EOF


```

Add this line to your kustomization.yaml:

```bash
cp ~/project/deploy/gelenv-stable/kustomization.yaml ~/project/deploy/gelenv-stable/kustomization.yaml.orig
printf "
- command: update
  path: transformers[+]
  value:
    site-config/block_ing.yaml      # block access to the ingress for the pods
" | yq -I 4 w -i -s - ~/project/deploy/gelenv-stable/kustomization.yaml

```

now we build and re-apply:

```bash
kustomize build -o site.yaml
kubectl apply -f site.yaml


```

Now log into Studio and try to use the Compute Server.
