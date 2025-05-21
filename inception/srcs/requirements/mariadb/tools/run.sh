#!/bin/sh

MARIADB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MARIADB_PASSWORD=$(cat /run/secrets/db_password)

cat > /etc/my.cnf.d/my.cnf <<eof

[mysqld]
skip-host-cache
bind-address=0.0.0.0
skip-name-resolve
skip-networking=0
port=3306

eof

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."

    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
    sleep 3

mariadbd-safe --datadir=/var/lib/mysql &

# Wait for the database to start
sleep 10

cat > init.sql <<eof

ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password;
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MARIADB_ROOT_PASSWORD}');

CREATE DATABASE IF NOT EXISTS ${MARIADB_DATABASE};

CREATE USER '${MARIADB_MYSQL_LOCALHOST_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';

GRANT ALL PRIVILEGES ON ${MARIADB_DATABASE}.* TO '${MARIADB_MYSQL_LOCALHOST_USER}'@'%';
GRANT ALL PRIVILEGES ON *.* TO '${MARIADB_MYSQL_LOCALHOST_USER}'@'%';
FLUSH PRIVILEGES;

eof

/usr/bin/mariadb --user=root < init.sql

mysqladmin -u root --password="$MARIADB_ROOT_PASSWORD" shutdown

find /var/lib/mysql/ -type f -exec chmod 777 {} \; 
find /var/lib/mysql/ -type d -exec chmod 777 {} \; 
fi

exec mariadbd-safe --datadir=/var/lib/mysql
