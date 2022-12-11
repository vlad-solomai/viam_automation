#!/bin/bash
MYSQL_REPLICA=$1
function operator_name() {

        JSON_STRING='{"data":['


        mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "select distinct operator_id, operator_name from mv_finance_report order by operator_id;" > /tmp/autodiscovery_spin_count_operator_name
        OPERATORS_ID=$(tail -n +2 /tmp/autodiscovery_spin_count_operator_name | awk -F  "\t" '{print $1}')


        for i in $OPERATORS_ID; do
                COUNT=$(mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "SELECT count(*) FROM tx_payment_journal_historical j join tx_player p on j.from_player_id=p.player_id where p.operator_id=$i and payment_date >= current_timestamp - interval 3 hour;")

                DEBIT_COUNT=$(($(echo ${COUNT} |  awk -F  " " '{print $2}') / 3))

                pattern="^$i\t"
                name=$(cat  /tmp/autodiscovery_spin_count_operator_name | grep -P "$pattern" | sed "s/.*\t//")
                JSON_STRING+='{"id":"'"$i"'","operator_name":"'
                JSON_STRING+=''$name'","transactions_count":"'"$DEBIT_COUNT"'"},'

        done
        JSON=${JSON_STRING::-1}
                JSON+=']}'
                echo $JSON

}
operator_name
