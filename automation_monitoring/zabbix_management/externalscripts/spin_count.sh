#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MYSQL_REPLICA=$1
INTERVAL=$3

function count() {

       mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf -h $MYSQL_REPLICA -e exit 2>/dev/null
       mysqlstatus=`echo $?`

       if [ $mysqlstatus -ne 0 ]; then

           COUNT=0
           echo $COUNT

        else

        COUNT=$(mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "select count(*) as transactions from tx_payment_journal_historical j join tx_player p on j.from_player_id = p.player_id and j.from_player_id != 1 where p.operator_id = $1 and payment_date between timestamp(date_sub(now(), interval $INTERVAL minute)) and timestamp (now())\G"|grep 'transactions:'|sed -e 's/ *transactions: //')

        echo $COUNT
    fi
}


function count_total() {
       COUNT=$(mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "select count(*) as transactions from tx_payment_journal_historical j join tx_player p on j.from_player_id = p.player_id and j.from_player_id != 1 where payment_date between timestamp(date_sub(now(), interval $INTERVAL minute)) and timestamp (now())\G"|grep 'transactions:'|sed -e 's/ *transactions: //')

     echo $COUNT
}


case "$2" in
        
        total)
            count_total
            ;;
        *)
            count $2
            ;;
esac
