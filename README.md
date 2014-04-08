lamp-tools
==========

webuseradd.sh
=============

Simple apache2 vhost creation script

        root@webserver00:~# ./webuseradd.sh mydomain.com

        Chek and secure this data:

                SFTP USERNAME: mydomain.com
                SFTP PASSWORD: q7hJqpDuu2xieGvd
        
                SQL USERNAME: mydomain_com
                SQL PASSWORD: SlhKE82YbXpz9MjG
                SQL DB NAME: mydomain_com
        
                VHOST: http://mydomain.com
                DOMAIN NAME: mydomain.com
                WEB ROOT: /var/www/mydomain.com/htdocs
                CHROOT JAIL: /var/www/mydomain.com

        Are you sure to continue? Check again. [y/N] y
        Do you want to add a www.mydomain.com alias? [y/N] y
        Do you want to reload apache? (apache2ctl graceful) [y/N] y
        root@webserver00:~# 

backup.sh
=========

Simple vhost & databases backup script

You may want to schedule this task by adding a cron like this:

        00 03 * * 0	/path/to/backup.sh > /dev/null 2>&1
