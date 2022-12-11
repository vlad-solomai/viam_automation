#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
MYSQL_REPLICA=$1
INTERVAL=$3

function count() {
#        COUNT=$(mysql --defaults-file=/etc/zabbix/.my.cnf --defaults-group-suffix=$MYSQL_REPLICA -h $MYSQL_REPLICA -e "select count(*) as transactions from tx_payment_journal j join tx_player p on j.from_player_id = p.player_id and j.from_player_id != 1 where p.operator_id = $1 and payment_date between timestamp(date_sub(now(), interval $INTERVAL minute)) and timestamp (now())\G"|grep 'transactions:'|sed -e 's/ *transactions: //')

       mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf -h $MYSQL_REPLICA -e exit 2>/dev/null
       mysqlstatus=`echo $?`

       if [ $mysqlstatus -ne 0 ]; then

           COUNT=0
           echo $COUNT

        else

        COUNT=$(mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "select count(*) as transactions from tx_payment_journal j join tx_player p on j.from_player_id = p.player_id and j.from_player_id != 1 where p.operator_id = $1 and payment_date between timestamp(date_sub(now(), interval $INTERVAL minute)) and timestamp (now())\G"|grep 'transactions:'|sed -e 's/ *transactions: //')

# Uncomment this line for HISTORICAL table
 #       COUNT=$(mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "select count(*) as transactions from tx_payment_journal_historical j join tx_player p on j.from_player_id = p.player_id and j.from_player_id != 1 where p.operator_id = $1 and payment_date between timestamp(date_sub(now(), interval $INTERVAL minute)) and timestamp (now())\G"|grep 'transactions:'|sed -e 's/ *transactions: //')

        echo $COUNT
    fi
}

function count_several() {

       mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf -h $MYSQL_REPLICA -e exit 2>/dev/null
       mysqlstatus=`echo $?`

       if [ $mysqlstatus -ne 0 ]; then

           COUNT=0
           echo $COUNT

        else

        COUNT=$(mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "select count(*) as transactions from tx_payment_journal j join tx_player p on j.from_player_id = p.player_id and j.from_player_id != 1 where p.operator_id in ($1) and payment_date between timestamp(date_sub(now(), interval $INTERVAL minute)) and timestamp (now())\G"|grep 'transactions:'|sed -e 's/ *transactions: //')

# Uncomment this line for HISTORICAL table
#        COUNT=$(mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "select count(*) as transactions from tx_payment_journal_historical j join tx_player p on j.from_player_id = p.player_id and j.from_player_id != 1 where p.operator_id in ($1) and payment_date between timestamp(date_sub(now(), interval $INTERVAL minute)) and timestamp (now())\G"|grep 'transactions:'|sed -e 's/ *transactions: //')

        echo $COUNT
        fi
}

function count_total() {
#        COUNT=$(mysql --defaults-file=/etc/zabbix/.my.cnf --defaults-group-suffix=$MYSQL_REPLICA -h $MYSQL_REPLICA -e "select count(*) as transactions from tx_payment_journal j join tx_player p on j.from_player_id = p.player_id and j.from_player_id != 1 where payment_date between timestamp(date_sub(now(), interval $INTERVAL minute)) and timestamp (now())\G"|grep 'transactions:'|sed -e 's/ *transactions: //')

       COUNT=$(mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "select count(*) as transactions from tx_payment_journal j join tx_player p on j.from_player_id = p.player_id and j.from_player_id != 1 where payment_date between timestamp(date_sub(now(), interval $INTERVAL minute)) and timestamp (now())\G"|grep 'transactions:'|sed -e 's/ *transactions: //')

# Uncomment this line for HISTORICAL table
#       COUNT=$(mysql --defaults-file=/etc/zabbix/.$MYSQL_REPLICA.cnf  -h $MYSQL_REPLICA -e "select count(*) as transactions from tx_payment_journal_historical j join tx_player p on j.from_player_id = p.player_id and j.from_player_id != 1 where payment_date between timestamp(date_sub(now(), interval $INTERVAL minute)) and timestamp (now())\G"|grep 'transactions:'|sed -e 's/ *transactions: //')

     echo $COUNT
}


case "$2" in
        
    
        bv)
                count 2
                ;;
        ladbrokes)
                count 26
                ;;
    wh)
                count 28
                ;;
        888)
                count 31
                ;;
        bv_si)
            count 32
            ;;
        rank)
                count 38
                ;;
        gvc)
                count 40
                ;;       
        relax)
                count 41
                ;;
        rush)
                count 43
                ;;
    ainsworth)
                count 44
                ;;
        pop)
            count 45
            ;;
    bv)
                count 48
                ;;
        rush_social)
                count 49
                ;;  
        white_hat)
                count 50
                ;;
        888_casino)
            count 51
            ;;
        rush_colombia)
            count 53
            ;;
    betfred)
                count 54
                ;;
        golden_nugget)
                count 56
                ;;
        coral)
                count 59
                ;;
        netbet_com)
            count 61
            ;;
        netbet_ro)
            count 62
            ;;
        mohegan_sun)
                count 66
                ;;
        resorts_casino)
                count 67
                ;;
         parx)
                count 74
                ;;
        caesars_casino)
                count 77
                ;;
        buzzbingo)
            count 81
            ;;
        caliente)
            count 82
            ;;
        novibet_com)
            count 83
            ;;
        novibet_uk)
            count 86
            ;;
        ladbrokes)
                count 95
                ;;
        kindred)
                count 100
                ;;
        caesars_pa)
                count 117
                ;;
        gvc_nj)
                count 127
                ;;
        gvc_pa)
                count 128
                ;;
        gvc_eu)
                count_several 129,130,131,132,133,134,135,136
                ;;
        rush_mi)
                count 137
                ;;
        olg)
                count 156
                ;;
        borgata_mi)
                count 184
                ;;
        betmgm)
                count 183
                ;;
        total)
                count_total
                ;;
        *)
                echo $"Usage $0 {IP uncompleted}"
                exit
esac
