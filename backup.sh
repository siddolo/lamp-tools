#!/bin/sh
#
# Simple vhost & databases backup script
# Coded by Pasquale 'sid' Fiorillo <info@pasqualefiorillo.it>
# This code is released under GPL v2 license. Feel free to use it.
#
# You may want to schedule this task by adding a cron like this
# 00 03 * * 0	/path/to/backup.sh > /dev/null 2>&1
#
# WARNING: chown to root this file and restrict it's permission to 700

WWWSOURCEDIR="/var/www"
WWWBACKUPDIR="/var/backups/www"
MYSQLBACKUPDIR="/var/backups/mysql"
REMOVEOLDERTHANDAYS=30

ROOTSQLUSER="root"
ROOTSQLPASS="pwd"
MYSQLHOST="localhost"

# backup vhosts
for VHOST in $(ls ${WWWSOURCEDIR} | grep -v index.html)
do
	tar -pczf ${WWWBACKUPDIR}/$(date +%d-%m-%Y)_${VHOST}.tar.gz ${WWWSOURCEDIR}/${VHOST} > /dev/null 2>&1
done

# backup databases
for DATABASE in $(mysql -h ${MYSQLHOST} -u ${ROOTSQLUSER} -p${ROOTSQLPASS} --batch --silent -e 'SHOW DATABASES' | grep -v -e mysql -e information_schema -e performance_schema -e phpmyadmin)
do
	mysqldump -h ${MYSQLHOST} -u ${ROOTSQLUSER} -p${ROOTSQLPASS} ${DATABASE} | gzip > ${MYSQLBACKUPDIR}/$(date +%d-%m-%Y)_${DATABASE}.sql.gz
done

# remove old backup
find ${WWWBACKUPDIR}/* -type f -mtime +${REMOVEOLDERTHANDAYS} -delete
find ${MYSQLBACKUPDIR}/* -type f -mtime +${REMOVEOLDERTHANDAYS} -delete
