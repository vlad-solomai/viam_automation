#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MYSQL_REPLICA=$1
MYSQL_PASS='####'
MYSQLUSER='###'
MYSQL_DB='###'

status=$(mysql -h $MYSQL_REPLICA -P 3306 -A -u$MYSQLUSER -p$MYSQL_PASS $MYSQL_DB -e "SELECT CONCAT(b.game_name,' - ',a.actualRTP,' |') as ' ' from rtp_bad_results a left join core_game b on a.game_id=b.game_id order by game_name ASC\G")

#limit output
status=${status:0:20000}
if [ -z "$status" ]; then
    # OK
    echo "ALL_RTPs_FINE"
else
    # ERROR
    echo $status
#    echo "ALL_RTPs_FINE"
fi
