#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MYSQL_REPLICA=$1

function count_incomplete() {
        COUNT=$(mysql --defaults-file=/etc/zabbix/.my.cnf -h $MYSQL_REPLICA -e 'SELECT count(*) as transactions FROM tx_payment_journal WHERE to_player_id != 1 AND amount != 0 AND complete = 0 AND   payment_date between timestamp(date_sub(now(), interval 60 minute)) and timestamp (now())\G'|grep 'transactions:'|sed -e 's/ *transactions: //')
    echo $COUNT
}

function count_unfinished() {
        COUNT=$(mysql --defaults-file=/etc/zabbix/.my.cnf -h $MYSQL_REPLICA -e 'SELECT count(a) as transactions FROM (select game_cycle_id as a from tx_payment_journal j left join tx_completed_game_cycle p on j.game_cycle_id = p.payment_reference left join tx_player pl on j.to_player_id=pl.player_id where p.payment_reference is null and j.cancelled!=1 and payment_date between timestamp(date_sub(now(), interval 60 minute)) and timestamp (now()) group by game_cycle_id) b\G'|grep 'transactions:'|sed -e 's/ *transactions: //')
        echo $COUNT
}

function count_canceled() {
        COUNT=$(mysql --defaults-file=/etc/zabbix/.my.cnf -h $MYSQL_REPLICA -e 'SELECT count(*) as transactions FROM game_rgs.tx_cancelled_payment where cancelled_date between timestamp(date_sub(now(), interval 60 minute)) and timestamp (now())\G'|grep 'transactions:'|sed -e 's/ *transactions: //')
        echo $COUNT
}

case "$2" in
        incomplete)
                count_incomplete
                ;;
    unfinished)
                count_unfinished
                ;;
    canceled)
                count_canceled
                ;;
        *)
                echo $"Usage $0 {IP uncompleted}"
                exit
esac
