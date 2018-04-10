# This file is part of lucamaro/docker-opendcim

## CUSTOMIZED VARIABLES
# db hostname, don't change if you want to use the docker link to db container
# otherwise change DBHOST name and empty DBLINK_OPT/DBLINK_PAIR
DBHOST=db
DBLINK_OPT="--link"
DBLINK_PAIR="dcimdb:db"
# root password for mysql
ROOT_DB_PASSWD=changeme
# schema user and password
DCIM_DB_SCHEMA=dcim
DCIM_DB_USER=dcim
DCIM_DB_PASSWD=changeme
# auth method
DCIM_AUTH=Apache
#DCIM_AUTH=LDAP
# port exposing the service by your container
PORT=80

# SSL configurations
#SSL_ON=1
#SSL_PORT=443
#SSL_CERTS_VOLUME_OPT="-v"
#SSL_CERTS_VOLUME_PATH_PAIR="/work/docker-opendcim/certs:/etc/ssl/certs"

## don't change this
VERSION=4.5-d2


# lists all available targets
list:
	@sh -c "$(MAKE) -p no_targets__ | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' | grep -v 'make\[1\]' | grep -v 'Makefile' | sort"
# required for list
no_targets__:

build:
	@docker pull php:5-apache
	@docker build -t lucamaro/docker-opendcim:$(VERSION) .

init_db:
	@docker run --name dcimdb -v /db_backup -e MYSQL_ROOT_PASSWORD=$(ROOT_DB_PASSWD) -d mariadb
	@echo "Waiting for db to be up..."
	@sleep 25
	@docker exec -it dcimdb mysql -uroot -p$(ROOT_DB_PASSWD) -e "create database $(DCIM_DB_SCHEMA)"
	@docker exec -it dcimdb mysql -uroot -p$(ROOT_DB_PASSWD) -e "grant all privileges on $(DCIM_DB_SCHEMA).* to '$(DCIM_DB_USER)' identified by '$(DCIM_DB_PASSWD)'"

backup_db:
	@docker exec -it dcimdb sh -c "mysqldump -uroot -p$(ROOT_DB_PASSWD) --all-databases | gzip -9 > /db_backup/dump.sql.gz"

restore_db:
	 @$(shell zcat dump.sql.gz | docker exec -i dcimdb mysql -uroot -p$(ROOT_DB_PASSWD))

#TODO: SSL_PORT optional paramenter wll be addressed in sh script	
init_dcim:
	@docker run -d -p $(PORT):80 \
		-e DBHOST=$(DBHOST) \
		-e DCIM_DB_SCHEMA=$(DCIM_DB_SCHEMA) \
		-e DCIM_DB_USER=$(DCIM_DB_USER) \
		-e DCIM_DB_PASSWD=$(DCIM_DB_PASSWD) \
		-e DCIM_AUTH=$(DCIM_AUTH) \
		$(DBLINK_OPT) $(DBLINK_PAIR) \
		-e SSL_ON=$(SSL_ON) \
		$(SSL_CERTS_VOLUME_OPT) $(SSL_CERTS_VOLUME_PATH_PAIR) \
		-p $(SSL_PORT):443 \
		--name dcim  lucamaro/docker-opendcim:$(VERSION)

update:
	@docker stop dcim
	@docker run -d -p $(PORT):80 -e DBHOST=$(DBHOST) \
		-e DCIM_DB_SCHEMA=$(DCIM_DB_SCHEMA) \
		-e DCIM_DB_USER=$(DCIM_DB_USER) \
		-e DCIM_DB_PASSWD=$(DCIM_DB_PASSWD) \
		-e DCIM_AUTH=$(DCIM_AUTH) \
		$(DBLINK_OPT) $(DBLINK_PAIR) \
		--volumes-from=dcim \
		--name dcim_next lucamaro/docker-opendcim:$(VERSION)

update-after-install:
	@docker exec -it dcim_next rm /var/www/dcim/install.php
    
undo_update:
	-@docker stop dcim_next
	-@docker rm -v dcim_next
	@docker start dcim

confirm_update:
	@docker rm -v dcim
	@docker rename dcim_next dcim

start:
	-@docker start dcimdb dcim

after-install:
	@docker exec -it dcim rm /var/www/dcim/install.php
	$(info Change dcim password...)
	@docker exec -it dcim htpasswd /var/www/secure/opendcim.password dcim

stop:
	-@docker stop dcim
	-@docker stop dcimdb

logs:
	@docker logs dcim

generate_certs:
	@mkdir -p certs
	@openssl req -x509 -newkey rsa:4096 -keyout certs/ssl-cert.key -out certs/ssl-cert.pem -days 365 -nodes
