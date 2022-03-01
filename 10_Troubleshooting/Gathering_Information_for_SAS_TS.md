![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Gathering Information for SAS Tech Support

1. this is it:

    ```bash
    NS=viya4

    current_time=$(date "+%Y.%m.%d-%H.%M.%S")
    echo "Current Time : $current_time"

    for_ts () {
        kubectl -n $1 $2 | tee ~/$1/for_ts_$3.$current_time.txt

    }

    #rm ~/viya4/*.txt
    for_ts viya4 'get nodes,all,pods,pvc,ing -o wide' get_all
    for_ts viya4 'describe pods,pvc,ing,services,nodes' describe_all

    grep username  bundles/default/internal/secrets.yaml | tee ~/viya4/for_ts_order.$current_time.txt.txt


    ```
