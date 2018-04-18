[OpenDCIM](https://www.opendcim.org) is:

> An Open Source Software package for managing the infrastructure of a 
> data center, no matter how small or large.  Initially developed 
> in-house at Vanderbilt University Information Technology Services by 
> Scott Milliken.  

## Launch

First customize `.env` file.

| Var               | Value                                | Note |
|-------------------|--------------------------------------|------|
|DCIM_HTTP_PORT          |80                                    |      |
|DCIM_HTTPS_PORT          |443                                    |      |
|ADMINER_PORT       |8080                                  |      |
|MYSQL_ROOT_PASSWORD|changerootdbpwd                       |      |
|MYSQL_DATABASE     |dcim                                  |      |
|MYSQL_USER         |dcim                                  |      |
|MYSQL_PASSWORD     |changeme                              |      |
|DCIM_PASSWD   |webdcimpwd    |default pwd for logging with dcim user for the first time  |
|DCIM_PASSWD_FILE   |/secrets/opendcim_password    |useful with swarm secrets |
|SSL_CERT_FILE      |/certs/ssl-cert.pem|if both cert and key are set, SSL will be enabled      |
|SSL_KEY_FILE       |/certs/opendcim-ssl-cert.key|see above comment      |


Build and start dcim container with:

    docker-compose up

If you need to start a db:

    docker-compose -f docker-compose.yml -f docker-compose-db.yml up


After completing the install procedure, remove install.php file:

    docker exec -it opendcim_webapp_1 rm /var/www/dcim/install.php

## Use TLS

Optionally generate self signed certificates with the following commands:

    mkdir -p certs
    openssl req -x509 -newkey rsa:4096 -keyout certs/opendcim-ssl-cert.key -out certs/opendcim-ssl-cert.pem -days 365 -nodes -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.com"

Add volume with certificates to docker-compose file:

    volumes:
      - ./certs:/certs:ro 
 

### Enable LDAP auth

After openDCIM is working with admin permissions (i.e. dcim user) go to "Edit Configuration" menu --> LDAP tab and configure all
the parameters according to your LDAP configuration.

Then, disable basic auth and enable LDAP auth:

    docker exec -it opendcim_webapp_1 mv /var/www/dcim/.htaccess /var/www/dcim/.htaccess.no
    docker exec -it opendcim_webapp_1 sed -i "s/Apache/LDAP/" /var/www/dcim/db.inc.php

Now you should be able to login with LDAP users credentials.

# Restore installation

## Restore images

    docker run --rm -v opendcim_dcim_data:/data -v /your/path/to/backup/dir:/backup -it alpine sh

Then restore your backup located in container under `/backup` dir into `/data/images` `/data/pictures` and `/data/drawings`.

**WARN: since version 18.01 this must be in place before launching DCIM for the first time, sinci 
it will populate an image cache to improve performance in cabinet rendering.**


## Restore DB

    zcat dcim.sql.gz | docker exec -i opendcim_db_1 mysql -u root -pchangerootdbpwd dcim

    docker exec -it opendcim_db_1 mysql -u root -pchangerootdbpwd  dcim


