#!/bin/bash
#
# Simple vhost creation script (nginx + php-fpm)
# Coded by Pasquale 'sid' Fiorillo <info@pasqualefiorillo.it>
# This code is released under GPL v2 license. Feel free to use it.
#
# WARNING: chown to root this file and restrict it's permission to 700

# ====== CONFIG ======
WEB_DIR_BASE_PATH="/var/www"
DEFAULT_SHELL="/bin/bash"
GROUP="www-data"			# Additional group added to the user used to resctrict it in sftp only (/etc/ssh/sshd_config)
CHMOD="750"				# Default permission of /var/www/mydomain/(www|log|tmp) directory
UMASK="077"				# Default permission of files uploaded via sftp
SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"
PHP_FPM_POOL_PATH="/etc/php5/fpm/pool.d"
# ====== /CONFIG ======

if [ $# -lt 1 ]; then
	printf "\nUsage: $0 vhost_name\n"
        printf "Example: $0 mydomain.com\n"
        printf "Example: $0 blog.myadomain.com\n\n"
        exit
fi;

VHOST_NAME=$1
SFTP_PASSWORD=`tr -cd '[:alnum:]_!\-' < /dev/urandom | fold -w16 | head -n1`
HOME_DIR="${WEB_DIR_BASE_PATH}/${VHOST_NAME}"

printf "\nChek and secure this data:"
printf "\n\tVHOST: http://${VHOST_NAME}"
printf "\n\tHOME: ${HOME_DIR}"
printf "\n\tSFTP USERNAME: ${VHOST_NAME}"
printf "\n\tSFTP PASSWORD: ${SFTP_PASSWORD}\n\n"

read -r -p "Are you sure to continue? Check again. [y/N] " response
case $response in
        [yY])
		useradd -G ${GROUP} -d ${HOME_DIR} -M -s ${DEFAULT_SHELL} ${VHOST_NAME}
		echo "${VHOST_NAME}:${SFTP_PASSWORD}" | chpasswd
		cp -R ${WEB_DIR_BASE_PATH}/skeleton ${HOME_DIR}
		echo "umask ${UMASK}" >> ${HOME_DIR}/.profile
		chown ${VHOST_NAME}:${GROUP} ${HOME_DIR}/*
		chown ${VHOST_NAME}:${GROUP} ${HOME_DIR}/.profile
		chown root:root ${HOME_DIR}
		chmod ${CHMOD} ${HOME_DIR}/*
		chmod 755 ${HOME_DIR}
		read -r -p "Do you want to add a www.${VHOST_NAME} alias? [y/N] " response
		case $response in
			[yY])
				WWW_ALIAS=" www.${VHOST_NAME}"
			;;
			*)
				WWW_ALIAS=""
			;;
		esac

		cp ${SITES_AVAILABLE}/skeleton ${SITES_AVAILABLE}/${VHOST_NAME}
		sed -i 's/__VHOST_NAME__/'${VHOST_NAME}'/g' ${SITES_AVAILABLE}/${VHOST_NAME}
		sed -i 's/__WWW_ALIAS__/'${WWW_ALIAS}'/g' ${SITES_AVAILABLE}/${VHOST_NAME}
		ln -s ${SITES_AVAILABLE}/${VHOST_NAME} ${SITES_ENABLED}/${VHOST_NAME}

		cp ${PHP_FPM_POOL_PATH}/skeleton ${PHP_FPM_POOL_PATH}/${VHOST_NAME}.conf
		sed -i 's/__VHOST_NAME__/'${VHOST_NAME}'/g' ${PHP_FPM_POOL_PATH}/${VHOST_NAME}.conf

		read -r -p "Do you want to restart services? [y/N] " response
		case $response in
			[yY])
				service nginx restart
				service php5-fpm restart
			;;
			*)
				echo "Don't forget to restart nginx & php5-fpm manually!"
			;;
		esac
	;;
	*)
		exit
	;;
esac
