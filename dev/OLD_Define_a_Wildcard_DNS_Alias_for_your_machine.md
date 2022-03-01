![Global Enablement & Learning](https://gelgitlab.race.sas.com/GEL/utilities/writing-content-in-markdown/-/raw/master/img/gel_banner_logo_tech-partners.jpg)

# Define a Wildcard DNS Alias for your machine

## Background

In order to access the various applications we will be setting up, we will need to be able to have disctinct URLs for each of them.

In this hands-on, you will define what is called a **wildcard** DNS alias in addition to the official name of your race machine.

Please be careful with these steps. They are not complex but the touch SAS' DNS and so can have a wider impact than expected

## Determining the hostname of your machine

Assuming that you are using the provided machines, your Fully Qualified Hostname should end with *.race.sas.com*.

To confirm that, execute:

```sh
hostname -f
```

the result should be either:

* `pdcesxNNNNN.race.sas.com`
* `rextNN-NNNN.race.sas.com`
* `aznvirNNNNN.race.sas.com`

If you get a different result, stop here and consult the course facilitator before continuing.

## Connect to *names.na.sas.com*

1. Open a browser on your workstation and connect to <https://names.na.sas.com/>
1. When prompted for credentials, authenticate with your own SAS credentials

1. On the first screen, select:

    ![alt](img/names01.png)

1. On the second screen, select:

    ![alt](img/names02.png)

1. On the third screen, enter your host name, and click nextt:

    ![alt](img/names03.png)

1. On the fourth screen, you will have to enter your Alias:

   1. If should be the Fully Qualified Domain Name of your RACE machine, preceded by `*.`. ( a star (`*`) and a dot (`.`))
   1. If your hostname was `pdcesx00000.race.sas.com`, your alias should be `*.pdcesx00000.race.sas.com`

1. It should look like the following:

    ![alt](img/names04.png)

1. If you see the following message, it means someone else already created that alias in the past, and so there is no need to do it again. Congrats, you can just close that page:

    ![alt](img/names05.png)

1. On the next screen check the tick box, and click next:

    ![alt](img/names06.png)

1. And on the final screen, just click *Submit Change*

    ![alt](img/names07.png)

1. At this point, you can close that web page, and wait to receive an e-mail informing you that your DNS alias is ready.

## Confirming that Wildcard DNS alias is working

In order to make sure that what we did worked, make sure that you get the same IP back when you ping the FQDN and when you ping any combination of `something.<FQDN>`.

For example, you can test it out like this:

![alt](img/pingtest.png)
