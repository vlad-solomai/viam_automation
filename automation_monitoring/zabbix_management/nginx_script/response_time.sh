#!/bin/bash

LOG_FILE=/usr/local/openresty/nginx/logs/access.log
STRINGS=40000

function response_time() {
        COUNT=0
        TOTAL=0
        MAXIMUM=0
        COLLECT_DATA="/tmp/$1_$2.log"
        chown zabbix:zabbix /tmp/$1_$2.log
        chmod g+w /tmp/$1_$2.log

        LOCAL_MINS_NOW=$(date +'%Y:%H:%M:%S')
        LOCAL_MINS_PREV=$(date -d "1 min ago" +'%Y:%H:%M:%S')

        DATA_COLLECTION=$(tail -n $STRINGS $LOG_FILE | grep "$1"| awk -F"-" '{if (($2==200)||($2==499)) {print $0}}' > $COLLECT_DATA)
        RESPONSE_TIMES=$(sed -n "/$LOCAL_MINS_PREV/,/$LOCAL_MINS_NOW/p" $COLLECT_DATA | awk -F"-" '{print $3*1000}')

        for i in $RESPONSE_TIMES; do
                let "TOTAL+=$i"
                let "COUNT+=1"
                if [ $i -gt $MAXIMUM ]
                then
                    MAXIMUM=$i
                fi
        done
        if (($COUNT != 0)) ;then
                AVERAGE=$(($TOTAL / $COUNT))
                JSON_STRING='{"average":"'"$AVERAGE"'","maximum":"'"$MAXIMUM"'"}'
                echo $JSON_STRING 
        else    echo '{"average":"0","maximum":"0"}'

        fi

}


function response_time_account() {
        COUNT=0
        TOTAL=0
        COLLECT_DATA="/tmp/$1_$2.log"
        chown zabbix:zabbix /tmp/$1_$2.log
        chmod g+w /tmp/$1_$2.log

        LOCAL_MINS_NOW=$(date +'%Y:%H:%M:%S')
        LOCAL_MINS_PREV=$(date -d "1 min ago" +'%Y:%H:%M:%S')

        DATA_COLLECTION=$(tail -n $STRINGS $LOG_FILE | grep "$1".*"$2" | awk -F"-" '{if (($2==200)||($2==499)) {print $0}}' > $COLLECT_DATA)
        RESPONSE_TIMES=$(sed -n "/$LOCAL_MINS_PREV/,/$LOCAL_MINS_NOW/p" $COLLECT_DATA | awk -F"-" '{print $3*1000}')
        for i in $RESPONSE_TIMES; do
                let "TOTAL+=$i"
                let "COUNT+=1"
        done
        if (($COUNT != 0)) ;then
                echo $(($TOTAL / $COUNT))
        else    echo 0
        fi
}


case "$1" in
        gr)
            response_time $1
            ;;
        gvc-nj)
            response_time $1
            ;;
        pragmatic)
            response_time $1
            ;;
        ainsworth)
            response_time $1
            ;;
        magnet)
            response_time $1
            ;;
        highfive)
            response_time $1
            ;;
        oryx)
            response_time $1
            ;;
        wh)
            response_time $1
            ;;
        gvc)
            response_time $1
            ;;
        gvc-mi)
            response_time $1
            ;;        
        transactionV2)
            response_time $1
            ;;
        888-local)
            response_time $1
            ;;
        generic)
            response_time $1
            ;;
        push)
            response_time $1
            ;;
        rush)
            response_time $1
            ;;
        nyx-pa)
            response_time $1
            ;;
        rank-local)
            response_time $1
            ;;
        bv-local)
            response_time $1
            ;;
        pop-local)
            response_time $1
            ;;
        pop-buzzbingo)
            response_time $1
            ;;
        bv-si)
            response_time $1
            ;;
        gamingrealms)
            response_time $1
            ;;
        relax)
            response_time $1
            ;;
        bede-olg)
            response_time $1
            ;;
        account_debit)
            response_time_account account debit
            ;;
        account_creditAndComplete)
            response_time_account account creditAndComplete
            ;;
        bv-si-place-bet)
            response_time_account bv-si place-bet
            ;;
        bv-si-settle-bet)
            response_time_account bv-si settle-bet
            ;;
        bv-si-account-details)
            response_time_account bv-si account-details
            ;;
        bv-si-authenticate)
            response_time_account bv-si authenticate
            ;;
        gr_wager)
           response_time_account gamingrealms WAGER
           ;;
        gr_win)
            response_time_account gamingrealms WIN
            ;;
        pragmatic_balance)
            response_time_account pragmatic balance
            ;;
        pragmatic_debit)
            response_time_account pragmatic debit
            ;;
        pragmatic_creditAndComplete)
            response_time_account pragmatic creditAndComplete
            ;;
        pragmatic_completeBet)
            response_time_account pragmatic completeBet
            ;;
        ainsworth_balance)
            response_time_account ainsworth balance
            ;;
        ainsworth_debit)
            response_time_account ainsworth debit
            ;;
        ainsworth_creditAndComplete)
            response_time_account ainsworth creditAndComplete
            ;;
        magnet_withdraw)
            response_time_account magnet withdraw
            ;;
        magnet_deposit)
            response_time_account magnet deposit
            ;;
        highfive_credit)
            response_time_account  highfive CREDIT
            ;;
        highfive_debit)
            response_time_account highfive DEBIT
            ;;
        oryx_balance)
            response_time_account oryx balance
            ;;
        oryx_close)
            response_time_account oryx CLOSE
            ;;
        oryx_none)
            response_time_account oryx NONE
            ;;
        wh_balance)
            response_time_account riga balances
            ;;
        wh_transaction)
            response_time_account riga transactions
            ;;
        gvc_balance)
            response_time_account gameops balance
            ;;
        gvc_transaction)
            response_time_account gameops transaction
            ;;                
        *)
                echo $"Usage $0 {gr|pragmatic|ainsworth|magnet|hihgfive|oryx|wh|gvc|transactionV2|888-local|generic|push|gamingrealms|relax|account_debit|account_creditAndComplete}"
                exit
esac
