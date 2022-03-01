![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

<https://hub.helm.sh/charts/halkeye/guacamole>
<https://github.com/halkeye-helm-charts/guacamole>

* try this

    ```bash
    helm repo add halkeye https://halkeye.github.io/helm-charts/
    kubectl create ns guac
    helm uninstall guac --namespace=guac
    helm install guac halkeye/guacamole --version 0.2.1 --namespace=guac \
        --set ingress.enabled=true \
        --set ingress.hosts[0].host="guac.$(hostname -f)" \
        --set ingress.hosts[0].paths={"/"}

    ```

* or this

```
kubectl create ns guac
cd /tmp
git clone https://github.com/prabhatsharma/apache-guacamole-helm-chart
cd apache-guacamole-helm-chart


helm uninstall guac --namespace=guac
helm install guac  \
     . -f values.yaml \
     --namespace=guac \
     --set guacamole.ingress.hosts={"guac.$(hostname -f)"} \
     --set mysql.mysqlRootPassword="lnxsas"

pod=$(kubectl get pods -n guac | grep mysql | awk '{print $1}')
kubectl -n guac port-forward $pod 3306:3306 --address=0.0.0.0
h*kd-Pler34


kubectl --namespace guacamole port-forward svc/guacamole 8080:80
visit http://localhost:8080/guacamole in your browser. Default creds are guacadmin/guacadmin
```