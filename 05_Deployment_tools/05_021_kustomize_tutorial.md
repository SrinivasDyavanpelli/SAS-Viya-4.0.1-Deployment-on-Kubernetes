![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Kustomize tutorial

This is a WIP. Skip for now, or suggest a better HO exercise for kustomize

## Simple example

```sh
# create required folders and sample files
rm -Rf ~/kustomizetests
mkdir -p ~/kustomizetests/base
mkdir -p ~/kustomizetests/dev
mkdir -p ~/kustomizetests/prod
touch ~/kustomizetests/base/myapp-service.yaml
cd ~/kustomizetests
```

```yaml
# create a pod definition in base, those files will NEVER (EVER) be touched, we will just apply customization above them to create new resources definitions
cat > ./base/myapp.yaml << EOF
---
apiVersion: v1
kind: Pod
metadata:
  name: myapp
  labels:
    apptype: awesome
EOF
```

```yaml
# Create the base kustomization file that references the base objects
cat > ./base/kustomization.yaml << EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - myapp.yaml
  - myapp-service.yaml
EOF
```

Create a DEV overlays

```sh
echo " RISKLEVEL: LOW " > ./dev/overlay.yaml
```

```yaml
# Create the DEV kustomization file that references the DEV overlays
cat > ./dev/kustomization.yaml << EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: dev
resources:
  - ../base
configMapGenerator:
  - name: my-app-config
    behavior: add
    files:
      - overlay.yaml
EOF
```

Create a PROD overlays

```sh
echo " RISKLEVEL: HIGH " > ./prod/overlay.yaml
```

```yaml
# Create the DEV kustomization file that references the PROD overlays
cat > ./prod/kustomization.yaml << EOF
---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: prod
resources:
  - ../base
configMapGenerator:
  - name: my-app-config
    behavior: add
    files:
      - overlay.yaml
EOF
```

```sh
# BUILD THE MANIFEST FOR DEV AND PROD WITH KUSTOMIZE
kustomize build ./dev/ -o dev.yaml
kustomize build ./prod/ -o prod.yaml
```

<!--

## Advanced example

Copied from <https://learning.oreilly.com/library/view/kubernetes-a/9781838828042/b24e2507-bc8c-499c-bdb9-845bde4b1aa0.xhtml>

1. Let's make a working directory

    ```bash
    mkdir -p ~/project/nginx
    cd ~/project/nginx
    ```

1. Create a file called

    ```bash
    tee ~/project/nginx/deployment-nginx.yaml > /dev/null <<EOF
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment
      labels:
        app: nginx
    spec:
      replicas: 2
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
            - name: nginx
              image: nginx:1.7.9
              ports:
                - containerPort: 80
    EOF

    yamllint ~/project/nginx/deployment-nginx.yaml
    ```

1. Create a kustomize file

    ```bash
    cat <<EOF > ~/project/nginx/kustomization.yaml
    ---
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
      - deployment-nginx.yaml
    images:
      - name: nginx
        newName: nginx
        newTag: 1.16.0
    commonAnnotations:
      kubernetes.io/change-cause: "Initial deployment with 1.16.0"
    EOF

    yamllint ~/project/nginx/kustomization.yaml
    ```

1. Now we generate the manifest (to stdout)

    ```bash
    # either:
    #kubectl kustomize ~/project/nginx/
    # or
    kustomize build ~/project/nginx/
    ```

1. Now we apply the deployment

    ```bash
    kubectl apply -k ~/project/nginx/ -n default
    #kubectl get pods -n default -w
    ```

1. Update the kustomize file with a newer image

    ```bash
    cat <<EOF > ~/project/nginx/kustomization.yaml
    ---
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization
    resources:
      - deployment-nginx.yaml
    images:
      - name: nginx
        newName: nginx
        newTag: 1.17.0
    commonAnnotations:
      kubernetes.io/change-cause: "image updated with 1.17.0"
    EOF

    yamllint ~/project/nginx/kustomization.yaml
    ```

1. Now we generate the manifest (to stdout)

    ```bash
    # either:
    #kubectl kustomize ~/project/nginx/
    # or
    kustomize build ~/project/nginx/
    ```

1. Now we apply the deployment

    ```bash
    kubectl apply -k ~/project/nginx/ -n default
    watch kubectl get pods -n default
    ```

1. And we look at the deployment history:

    ```bash
    kubectl rollout history deployment nginx-deployment -n default
    ```
-->
