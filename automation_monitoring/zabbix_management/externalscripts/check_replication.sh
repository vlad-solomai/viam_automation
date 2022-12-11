#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MYSQL_REPLICA=$1
MYSQL_PASS='8Cf_jDY[U{!tYw+n'
MYSQLUSER='dw'
MYSQL_DB=$2
#--defaults-group-suffix=$MYSQL_REPLICA

status=$(mysql --defaults-file=/etc/zabbix/.my.cnf --defaults-group-suffix=$MYSQL_REPLICA  -h $MYSQL_REPLICA -u$MYSQLUSER -p$MYSQL_PASS $MYSQL_DB -e 'show slave status\G'|grep Slave_SQL_Running: |sed -e 's/ *Slave_SQL_Running: //')


if [ "$status" == "Yes" ]; then
    # OK
    echo 1
else
    # ERROR
    echo 0
fi
