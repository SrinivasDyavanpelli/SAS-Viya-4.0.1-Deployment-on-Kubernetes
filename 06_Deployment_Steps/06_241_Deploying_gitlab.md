![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Deploying Gitlab in Kubernetes

* [Deploy Gitlab](#deploy-gitlab)
  * [Using Helm to install Gitlab Server pieces](#using-helm-to-install-gitlab-server-pieces)
  * [Commit and push the viya 4 deployment files into gitlab](#commit-and-push-the-viya-4-deployment-files-into-gitlab)
  * [Setup gitlab-runner on intnode01](#setup-gitlab-runner-on-intnode01)
  * [Setup first project pipeline](#setup-first-project-pipeline)

<!--

tee  /tmp/codimd_values.yaml > /dev/null << EOF
---
storageClass: nfs-client
ingress:
  enabled: true
  hosts:
    - host: codimd.$(hostname -f)
      paths:
      - /
EOF

helm repo add codimd https://helm.codimd.dev/

 helm uninstall codimd \
    --namespace codimd

 helm install codimd \
    codimd/codimd --version 0.1.7 \
     -f /tmp/codimd_values.yaml \
    --namespace codimd
 -->

## Deploy Gitlab

### Using Helm to install Gitlab Server pieces

These instructions will walk you through how to setup your own gitlab inside of your kubernetes.

1. Clean up in case of re-deploy:

    ```bash
    kubectl delete namespace gitlab
    ```

1. Create a namespace for it:

    ```bash
    kubectl create namespace gitlab
    ```

1. Use Helm to deploy it:

    ```bash
    helm repo add gitlab https://charts.gitlab.io/
    helm repo update

    # doc: https://docs.gitlab.com/charts/installation/deployment.html
    # helm uninstall gitlab --namespace gitlab

    helm install gitlab gitlab/gitlab \
        --timeout 600s \
        --set global.hosts.domain=devops.$(hostname -f) \
        --set global.hosts.https=false \
        --set certmanager-issuer.email=me@example.com \
        --set global.edition=ce \
        --set nginx-ingress.enabled=false \
        --set global.ingress.enabled=true \
        --set global.ingress.class=nginx \
        --set global.ingress.tls.enabled=false \
        --namespace gitlab
    ```

1. This will take between about 5-6 minutes to be ready.
1. You want all the pods to be either Running on Completed (you should know how to check that)

    ```bash
    kubectl get pods -n gitlab

    ```

1. A scripted way to wait for these pods could be to run something like:

    ```sh
    waitforpods () {
        PODS_NOT_READY=99
        while [ "${PODS_NOT_READY}" != "0" ]
        do
            PODS_NOT_READY=$(kubectl get pods -n $1 --no-headers | grep -v Completed | grep -E -v '1/1|2/2' | wc -l)
            printf "\n\n\nWaiting for these ${PODS_NOT_READY} pods to be Running: \n"
            kubectl get pods -n $1 --no-headers | grep -v Completed | grep -E -v '1/1|2/2'
            sleep 5
        done
        printf "All pods in namespace $1 seem to be ready \n\n\n\n"
    }

    waitforpods gitlab
    ```

1. Once that is done, we can query Kubernetes for the default password for the root account in gitlab

    ```bash
    gitlab_root_pw=$(kubectl -n gitlab get secret \
                    gitlab-gitlab-initial-root-password \
                    -o jsonpath='{.data.password}' | base64 --decode )
    echo $gitlab_root_pw

    printf "\n* [GitLab URL (HTTP)](http://gitlab.devops.$(hostname -f)/ )  (User=root Password=${gitlab_root_pw})\n\n" | tee -a /home/cloud-user/urls.md

    ```

<!--
 Install the gitlab CLI

* run this

    ```bash

    #sudo curl -L https://github.com/clns/gitlab-cli/releases/download/0.3.2/gitlab-cli-`uname -s`-`uname -m` \
    #    -o /usr/local/bin/gitlab-cli

    #sudo chmod +x /usr/local/bin/gitlab-cli
    sudo pip install --upgrade python-gitlab

``` -->

### magic gitlab bootstrap

ignore this for now.

<!--
```sh

gitlab_host="https://gitlab.devops.$(hostname -f)"
gitlab_user="root"
gitlab_password=${gitlab_root_pw}

# curl for the login page to get a session cookie and the sources with the auth tokens
body_header=$(curl -k -c cookies.txt -i "${gitlab_host}/users/sign_in" -s)

# grep the auth token for the user login for
#   not sure whether another token on the page will work, too - there are 3 of them
csrf_token=$(echo $body_header | perl -ne 'print "$1\n" if /new_user.*?authenticity_token"[[:blank:]]value="(.+?)"/' | sed -n 1p)

# send login credentials with curl, using cookies and token from previous request
curl -k -b cookies.txt -c cookies.txt -i "${gitlab_host}/users/sign_in" \
    --data "user[login]=${gitlab_user}&user[password]=${gitlab_password}" \
    --data-urlencode "authenticity_token=${csrf_token}"

# send curl GET request to personal access token page to get auth token
body_header=$(curl -k -H 'user-agent: curl' -b cookies.txt -i "${gitlab_host}/profile/personal_access_tokens" -s)
csrf_token=$(echo $body_header | perl -ne 'print "$1\n" if /authenticity_token"[[:blank:]]value="(.+?)"/' | sed -n 1p)

# curl POST request to send the "generate personal access token form"
# the response will be a redirect, so we have to follow using `-L`
body_header=$(curl -k -L -b cookies.txt "${gitlab_host}/profile/personal_access_tokens" \
    --data-urlencode "authenticity_token=${csrf_token}" \
    --data 'personal_access_token[name]=golab-generated&personal_access_token[expires_at]=&personal_access_token[scopes][]=api')

# Scrape the personal access token from the response HTML
personal_access_token=$(echo $body_header | perl -ne 'print "$1\n" if /created-personal-access-token"[[:blank:]]value="(.+?)"/' | sed -n 1p)

echo ${personal_access_token}



curl -k --header "PRIVATE-TOKEN: ${personal_access_token}" \
    "${gitlab_host}/api/v4/namespaces"


curl -v -H "Content-Type:application/json" https://gitlab.example.com/api/v3/projects?private_token=12345 -d "{ \"name\": \"project_name\",\"namespace_id\": \"555\" }"

## create a group

curl -k -L -H "PRIVATE-TOKEN: ${personal_access_token}" \
    -X POST --data "name=MyDevOps&path=MyDevOps&description=MyDevOps" ${gitlab_host}/api/v4/groups

curl -k -X POST \
  "${gitlab_host}/api/v4/users?private_token=${personal_access_token}" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d '{ "email": "joe@sas.com",
  "username": "joe",
  "password": "lnxsas123",
  "admin": "yes",
  "skip_confirmation": "yes",
  "name": "joe"
  }'


``` -->


### Setup a simple gitlab user

1. Access your kubernetes-powered gitlab:

    ```bash
    printf "\n* [GitLab HTTP URL](http://gitlab.devops.$(hostname -f)/ )\n\n"
    ```

1. Select the **Register** option
1. Full Name: **Joe User**
1. Username: **joe**
1. Email: **joe@sas.com**
1. Email Confirmation: **joe@sas.com**
1. Password: **lnxsas123**

1. Click **Register**

### Create a gitlab project

1. Click on **Create a Project**
   * Project name: **Viya4Deploy**
   * Project slug: **viya4deploy**
   * Visibility Level: **Public**
   * Click **Create Project**

### Make sure that Lab environment files exist

1. Kick off the deployment

```sh
bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/_autodeploy-lab_.sh

```

1. Delete and re-create the lab namespace:

```bash
kubectl delete ns lab ; kubectl create ns lab

```

### Commit and push the viya 4 deployment files into gitlab

1. Navigate to the right folder, and tell git to remember our credentials:

    ```bash
    cd ~/project/deploy/
    git config --global credential.helper store
    git config --global http.sslVerify false

    git config --global user.email "Joe.User@sas.com"
    git config --global user.name "Joe User"
    git config --global user.name "joe"
    git config --global user.password "lnxsas123"

    git init

    ```

1. Add and commit the lab folder:

    ```bash
    git add lab
    git commit -m "committing lab, as-is"

    ```

1. Set up a new remote for the git project:

    ```bash
    git remote -v
    git remote add origin http://gitlab.devops.$(hostname -f)/joe/viya4deploy.git
    git remote -v
    git push --set-upstream origin master
    ```

1. This might fail with an authentication failure on the first run.
1. If so, try again, and when prompted, enter the credentials:
    * user: **joe**
    * pass: **lnxsas123**

Once the project has been pushed into gitlab, go to the web interface to browse it.

### Setup gitlab-runner on intnode01

1. First, install the gitlab-runner binaries on intnode01:

    ```bash
    curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.rpm.sh | sudo bash
    sudo yum install gitlab-runner -y
    ```

1. Navigate to the project's CI/CD page:

    ```bash
    printf "\n http://gitlab.devops.$(hostname -f)/joe/viya4deploy/-/settings/ci_cd \n"

    ```

1. Expand the **Runners** section

1. Copy the runner registration token.
1. Mine looks like the following: `pDLdYJX4B-TmJuCy2eQ9`

1. Now, back at the prompt, let's register that runner with gitlab:

    ```bash
    token="7Q84zGyqS4xG3NiymS8C"

    sudo gitlab-runner register \
       --non-interactive \
       --url "http://gitlab.devops.$(hostname -f)/" \
       --registration-token "${token}" \
       --executor "shell" \
       --description "runner-sasnode01" \
       --tag-list "sasnode01" \
       --run-untagged="true" \
       --locked="false" \
       --access-level="not_protected"
    ```

1. now, start the gitlab runner

    ```bash
    sudo gitlab-runner status
    sudo gitlab-runner start
    ```

1. If you now refresh the gitlab page, you should see a new runner.

1. Click on **Disable shared Runners**

1. Let gitlab-runner access kubernetes:

    ```bash
    sudo -u gitlab-runner bash -c "mkdir -p ~/.kube"
    sudo cp /home/cloud-user/.kube/config /home/gitlab-runner/.kube/config
    sudo bash -c "chown gitlab-runner:gitlab-runner /home/gitlab-runner/.kube/config"
    ```

### Setup first project pipeline

1. Create the .gitlab-ci.yml file

    ```bash
    # enable gitlab pipelines
    cd ~/project/deploy

    tee ./.gitlab-ci.yml > /dev/null << "EOF"
    ---
    before_script:
       - hostname
       - date

    stages:
       - tools
       - lint
       - build
       - test
       - commit
       - apply
       - validate

    Install YAML Lint:
        stage: tools
        script:
            - pip install --user yamllint

    Lint manifest:
        stage: lint
        allow_failure: true
        script:
            - yamllint ./lab/kustomization.yaml

    Build Manifest:
        stage: build
        script:
            - kustomize build ./lab/ -o ./lab/site.yaml

    Git Commit new stuff:
        stage: commit
        allow_failure: true
        script:
        - git add ./lab/site.yaml
        - git config --global credential.helper store
        - git config --global http.sslVerify false
        - git config --global user.email "gitlab-runner@sas.com"
        - git config --global user.name "Gitlab Runner"
        - git config --global user.name "joe"
        - git config --global user.password "lnxsas123"
        - git commit -m "Automatic Manifest Update"
        - git remote rm origin
        - git remote add origin http://gitlab.devops.$(hostname -f)/joe/viya4deploy.git
        - git push --set-upstream origin master
        #- git remote add origin git@$(http://gitlab.devops.$(hostname -f)/):$CI_PROJECT_PATH.git
        #- git push origin HEAD:$CI_COMMIT_REF_NAME

    Apply the lab manifest:
        stage: apply
        allow_failure: true
        script:
            - kubectl apply -n lab -f ./lab/site.yaml

    ensure the environment is healthy:
        stage: validate
        allow_failure: true
        script:
            - gel_OKViya4 -n lab --wait -ps --min-success-rate 80 --max-retries 30 --retry-gap 60

    EOF
    ```

1. and add it to version control:

    ```bash
    git add .gitlab-ci.yml
    git commit -m "adding CI goodness"
    git push

    ```

