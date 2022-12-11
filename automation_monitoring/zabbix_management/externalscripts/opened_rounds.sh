#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MYSQL_REPLICA=$1
START_DATE=$(date -d "3 days ago" +'%Y-%m-%d %H:%M')
END_DATE=$(date -d "2 days ago" +'%Y-%m-%d %H:%M')

function open_rounds() {

        COUNT=$(mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "select count(distinct(game_cycle_id)) from tx_payment_journal pj left join tx_player p on pj.from_player_id=p.player_id left join tx_completed_game_cycle c on pj.game_cycle_id=c.payment_reference left join core_game g on pj.game_id=g.game_id where payment_date>='$START_DATE' and payment_date<'$END_DATE' and (p.operator_id=40 or p.operator_id=95 or p.operator_id=59)  and complete=1 and cancelled=0 and c.completed_tx_id is null;"|sed -e 's/count(distinct(game_cycle_id))//g')

        echo $COUNT

}




case "$2" in
        
    

        gvc)
                open_rounds 
                ;;
        *)
                echo $"Usage $0 {IP uncompleted}"
                exit
esac
