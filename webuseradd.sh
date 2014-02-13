#!/bin/sh
#
# Simple apache2 vhost creation script
# Coded by Pasquale 'sid' Fiorillo <info@pasqualefiorillo.it>
# This code is released under GPL v2 license. Feel free to use it.
#
# sftp require sshd configuration:
# 
# ------- /etc/ssh/sshd_config -------
# Subsystem sftp internal-sftp
# Match Group www-data
#       ChrootDirectory /var/www/%u
# 		AllowTCPForwarding no
#       X11Forwarding no
#       ForceCommand internal-sftp
# ------------------------------------
#
# WARNING: chown to root this file and restrict it's permission to 700

ROOTSQLUSER="root"
ROOTSQLPASS="pwd"

if [ $# -lt 1 ]; then
        printf "\nUsage: $0 [vhost_name]\n"
        printf "Example: $0 mydomain.com\n"
        printf "Example: $0 blog.myadomain.com\n"
        printf "\nThis script will create for you:\n"
        printf " - sftp and MySql accounts\n"
        printf " - A webroot dir in /var/www/mydomain.com/htdocs\n"
        printf " - A CustomLog dir in /var/www/mydomain.com/log\n"
        printf " - A temp dir in /var/www/mydomain.com/log\n"
        printf " - A mysql database mydomain_com\n"
        printf " - A mydomain.com apache vhost\n"
        printf "\n"
        exit
fi;

VHOST_NAME=$1
DOMAIN_NAME=`echo $1 | awk -F. {'print $(NF-1) "." $NF'}`
SFTPUSER=$1
SQLUSER=`echo $1 | sed -e 's/\./_/g' | fold -w16 | head -n1`
SQLDB=${SQLUSER}
SFTPWD=`tr -cd '[:alnum:]' < /dev/urandom | fold -w16 | head -n1`
SQLPWD=`tr -cd '[:alnum:]' < /dev/urandom | fold -w16 | head -n1`

printf "\nChek and secure this data:\n"
printf "\n\tSFTP USERNAME: ${SFTPUSER}\n"
printf "\tSFTP PASSWORD: ${SFTPWD}\n"
printf "\n\tSQL USERNAME: ${SQLUSER}\n"
printf "\tSQL PASSWORD: ${SQLPWD}\n"
printf "\tSQL DB NAME: ${SQLDB}\n"
printf "\n\tVHOST: http://${VHOST_NAME}\n"
printf "\tDOMAIN NAME: ${DOMAIN_NAME}\n"
printf "\tWEB ROOT: /var/www/${VHOST_NAME}/htdocs\n"
printf "\tCHROOT JAIL: /var/www/${VHOST_NAME}\n\n"

read -r -p "Are you shure to continue? Check again. [y/N] " response
case $response in
        [yY])
		useradd -g www-data -d /var/www/${VHOST_NAME} -m -s /bin/false ${VHOST_NAME}
		echo "${VHOST_NAME}:${SFTPWD}" | chpasswd
		mkdir /var/www/${VHOST_NAME}/htdocs
		mkdir /var/www/${VHOST_NAME}/tmp
		mkdir /var/www/${VHOST_NAME}/log
		chown ${VHOST_NAME}:www-data /var/www/${VHOST_NAME}/htdocs
		chown ${VHOST_NAME}:www-data /var/www/${VHOST_NAME}/tmp
		chown ${VHOST_NAME}:www-data /var/www/${VHOST_NAME}/log
		chown root:root /var/www/${VHOST_NAME}
		chmod 700 /var/www/${VHOST_NAME}/htdocs
		chmod 700 /var/www/${VHOST_NAME}/tmp
		chmod 700 /var/www/${VHOST_NAME}/log
		chmod 755 /var/www/${VHOST_NAME}

		read -r -p "Do you want to add a www.${VHOST_NAME} alias? [y/N] " response
		case $response in
			[yY])
				cp /etc/apache2/sites-available/template_www_alias /etc/apache2/sites-available/${VHOST_NAME}
			;;
			*)
				cp /etc/apache2/sites-available/template /etc/apache2/sites-available/${VHOST_NAME}
			;;
		esac

		sed -i 's/__VHOST_NAME__/'${VHOST_NAME}'/g' /etc/apache2/sites-available/${VHOST_NAME}
		sed -i 's/__DOMAIN_NAME__/'${DOMAIN_NAME}'/g' /etc/apache2/sites-available/${VHOST_NAME}
		ln -s /etc/apache2/sites-available/${VHOST_NAME} /etc/apache2/sites-enabled/${VHOST_NAME}

		echo "CREATE DATABASE ${SQLDB}; GRANT ALL PRIVILEGES ON ${SQLDB}.* TO ${SQLUSER}@localhost IDENTIFIED BY '${SQLPWD}';" | mysql -u ${ROOTSQLUSER} -p${ROOTSQLPASS}

		read -r -p "Do you want to reload apache? (apache2ctl graceful) [y/N] " response
		case $response in
			[yY])
				apache2ctl graceful
			;;
		esac
	;;
	*)
		exit
	;;
esac
