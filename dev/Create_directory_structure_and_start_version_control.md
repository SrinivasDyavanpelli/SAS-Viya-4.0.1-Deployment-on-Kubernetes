![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Create directory structure and start version control

1. Create the structure:

    ```bash
    #rm -rf ~/project/
    mkdir -p ~/project/
    mkdir -p ~/project/ldap
    mkdir -p ~/project/ldap/basic
    mkdir -p ~/project/ldap/admin
    mkdir -p ~/project/deploy
    #mkdir -p ~/project/deploy/functional
    #mkdir -p ~/project/deploy/functional/site-config
    #mkdir -p ~/project/deploy/smoketest
    #mkdir -p ~/project/deploy/smoketest/site-config
    #mkdir -p ~/project/deploy/dev
    #mkdir -p ~/project/deploy/dev/site-config
    #mkdir -p ~/project/deploy/amoeba
    #mkdir -p ~/project/deploy/amoeba/site-config
    #mkdir -p ~/project/deploy/test
    #mkdir -p ~/project/deploy/test/site-config
    #mkdir -p ~/project/deploy/prod-hr
    #mkdir -p ~/project/deploy/prod-hr/site-config
    #mkdir -p ~/project/deploy/prod-sales
    #mkdir -p ~/project/deploy/prod-sales/site-config

    #touch ~/project/deploy/functional/kustomization.yaml
    #touch ~/project/deploy/dev/kustomization.yaml
    #touch ~/project/deploy/smoketest/kustomization.yaml
    #touch ~/project/deploy/test/kustomization.yaml
    #touch ~/project/deploy/prod-hr/kustomization.yaml
    #touch ~/project/deploy/prod-sales/kustomization.yaml
    ```

<!--
1. Now we intialize the git project:

    ```sh
    ## Put in your own info!
    git config --global user.email "Erwan.Granger@sas.com"
    git config --global user.name "Erwan Granger"
    cd ~/project
    git init
    ``` -->

1. this is what SAS will add:

    ```sh

    mkdir -p ~/project/deploy/minimal/bundles/
    mkdir -p ~/project/deploy/minimal/bundles/examples
    mkdir -p ~/project/deploy/minimal/bundles/examples/cas
    mkdir -p ~/project/deploy/minimal/bundles/examples/cas/configure-cas/
    touch ~/project/deploy/minimal/bundles/examples/readme.md
    touch ~/project/deploy/minimal/bundles/examples/cas/configure-cas/CAS_Configuration.md
    touch ~/project/deploy/minimal/bundles/examples/cas/configure-cas/cas-mpp-transformer_example.yaml
    touch ~/project/deploy/minimal/bundles/examples/cas/configure-cas/cas-smp-transformer_example.yaml
    mkdir -p ~/project/deploy/minimal/bundles/examples/air-gapped/
    touch ~/project/deploy/minimal/bundles/examples/air-gapped/Air-Gapped_Environments.md
    touch ~/project/deploy/minimal/bundles/examples/air-gapped/mirror_example.yaml
    mkdir -p ~/project/deploy/minimal/bundles/overlays
    mkdir -p ~/project/deploy/minimal/bundles/overlays/cas
    mkdir -p ~/project/deploy/minimal/bundles/overlays/data
    touch ~/project/deploy/minimal/site-config/cas-mpp-transformer.yaml
    touch ~/project/deploy/minimal/site.yaml

    ```

    ```sh
    printf "# Main Readme \n\n * [CAS Configuration](./cas/configure-cas/CAS_Configuration.md) \
            \n\n * [Air-Gapped Environments](air-gapped/Air-Gapped_Environments.md) \
            \n\n" \
            | tee ~/project/deploy/minimal/bundles/examples/readme.md

    ```

1. Make sure you visualize it properly:

    ```bash
    tree ~/project/
    cd ~/project/
    ```

    ```sh
    cat ~/project/deploy/minimal/bundles/examples/readme.md
    ```

<!--
## fun with VSCode

1. to more easily see the changes:

    ```sh
    printf "\n\n Click on this URL to open VSCode in your browser:\n\n      http://$(hostname -i):8080/ \n\n"

    docker run -it  -e PASSWORD=lnxsas  -p 0.0.0.0:8080:8080 -v "/home/cloud-user/project/:/home/coder/viya4/" codercom/code-server
    ``` -->

## Back to the main README

Go back to the [main readme](/README.md)