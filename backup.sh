#!/bin/sh
#
# Simple vhost backup script (local + aws s3)
# Coded by Pasquale 'sid' Fiorillo <info@pasqualefiorillo.it>
# This code is released under GPL v2 license. Feel free to use it.
#
# You may want to schedule this task by adding a cron like this
# 00 03 * * 0	/path/to/backup.sh > /dev/null 2>&1
#
# WARNING: chown to root this file and restrict it's permission to 700
# Use read-only mysql backup user:
# GRANT LOCK TABLES, SELECT ON DATABASE.* TO 'BACKUPUSER'@'%' IDENTIFIED BY 'PASSWORD';
# 
# Require aws-cli

WWWSOURCEPATH='/var/www'

BACKUPPATH='/var/backups/vhost'
S3PATH='s3://cf-www-aws/backups'

MYSQLUSER='backup'
MYSQLPASS='password'
MYSQLHOST='localhost'

# Regexp
EXCLUDEWWW='index\.html|default'
EXCLUDEDB='mysql|information_schema|performance_schema|phpmyadmin'

REMOVEOLDERTHANDAYS=10

LOGFILE="$(date +%Y-%m-%d)_backup.log"
MAILTO='user@domain.com'



echo "=== BACKUP STARTED AT $(date) ===" > ${BACKUPPATH}/${LOGFILE}

# backup vhosts
for VHOST in $(ls ${WWWSOURCEPATH} | grep -v -E "${EXCLUDEWWW}")
do
	FILENAME="$(date +%Y-%m-%d)_${VHOST}.tar.gz"
	echo "=== BACKUPPING VHOST ${VHOST} ===" >> ${BACKUPPATH}/${LOGFILE}
	/bin/tar -pczf ${BACKUPPATH}/${FILENAME} ${WWWSOURCEPATH}/${VHOST} >> ${BACKUPPATH}/${LOGFILE} 2>&1
	echo "=== COPYING ${FILENAME} TO S3 ===" >> ${BACKUPPATH}/${LOGFILE}
	/usr/local/bin/aws s3 cp ${BACKUPPATH}/${FILENAME} ${S3PATH}/ >> ${BACKUPPATH}/${LOGFILE} 2>&1
done

# backup databases
for DATABASE in $(mysql -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} --batch --silent -e 'SHOW DATABASES' | grep -v -E "${EXCLUDEDB}")
do
	FILENAME="$(date +%Y-%m-%d)_${DATABASE}.sql.gz"
	echo "=== BACKUPPING DATABASE ${DATABASE} ===" >> ${BACKUPPATH}/${LOGFILE}
	mysqldump -h ${MYSQLHOST} -u ${MYSQLUSER} -p${MYSQLPASS} ${DATABASE} | gzip > ${BACKUPPATH}/${FILENAME} 2>> ${BACKUPPATH}/${LOGFILE}
	echo "=== COPYING ${FILENAME} TO S3 ===" >> ${BACKUPPATH}/${LOGFILE}
	/usr/local/bin/aws s3 cp ${BACKUPPATH}/${FILENAME} ${S3PATH}/ >> ${BACKUPPATH}/${LOGFILE} 2>&1
done

# remove old backup
echo "=== REMOVE BACKUP FILES OLDER THAN ${REMOVEOLDERTHANDAYS} DAYS ===" >> ${BACKUPPATH}/${LOGFILE}
find ${BACKUPPATH}/* -type f -mtime +${REMOVEOLDERTHANDAYS} -delete >> ${BACKUPPATH}/${LOGFILE} 2>&1

echo "=== BACKUP STUPPED AT $(date) ===" >> ${BACKUPPATH}/${LOGFILE}
/usr/local/bin/aws s3 cp ${BACKUPPATH}/${LOGFILE} ${S3PATH}/ > /dev/null 2>&1

echo "Backup log in attachment" | mail -s "[$(hostname -a)] Backup report" -a "${BACKUPPATH}/${LOGFILE}" "${MAILTO}"
