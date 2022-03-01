![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Confirm that the deployment is up and responding

1. Get the saslogon pod name

    ```bash
    podname () {
    kubectl -n $2 get pods | grep $1 | awk  '{ print $1 }'
    }
    POD=$(podname saslogon viya4)

    kubectl -n viya4 -it  exec  $POD -- curl -kv saslogon

    ```
