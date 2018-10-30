#! /bin/sh


if [ ! -f /.configured ] ; then
	cp /var/www/dcim/db.inc.php-dist /var/www/dcim/db.inc.php

	if [ -f "$SSL_CERT_FILE" ] && [ -f "$SSL_KEY_FILE" ] ; then
		a2enmod ssl
		a2ensite default-ssl
		cd /etc/ssl/certs/
		cp $SSL_CERT_FILE ssl-cert.pem
		cp $SSL_KEY_FILE ssl-cert.key
	fi

	# for swarm secret
	if [ -f "$DCIM_PASSWD_FILE" ] ; then
		PASSWORD=$(cat $DCIM_PASSWD_FILE)
	elif [ ! -z "$DCIM_PASSWD" ] ; then
		PASSWORD=$DCIM_PASSWD
	else
		PASSWORD=dcim
	fi
	htpasswd -cb /data/opendcim.password dcim $PASSWORD

	cd /var/www/dcim
	for D in images pictures drawings ; do
		if [ ! -d /data/$D ] ; then
			mkdir /data/$D
		fi

		if [ -d /var/www/dcim/$D ] ; then
			mv /var/www/dcim/$D/* /data/$D
			rm -rf /var/www/dcim/$D
			ln -s /data/$D .
		fi

		chown www-data:www-data /data/$D
	done

	# fix permissions on images directory
	chmod 555 /data/images
	chown www-data:www-data /var/www/dcim/vendor/mpdf/mpdf/ttfontdata

	touch /.configured
fi

for param in "$@" ; do
	if [ "$param" = "--remove-install" ] ; then 
		rm -f /var/www/dcim/install.php
	elif [ "$param" = "--enable-ldap" ] ; then
		mv /var/www/dcim/.htaccess /var/www/dcim/.htaccess.no
		sed -i "s/Apache/LDAP/" /var/www/dcim/db.inc.php
	fi
done

exec docker-php-entrypoint -DFOREGROUND
