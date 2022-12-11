#!/bin/bash

LOG_FILE=/var/log/game/platform/platform.log
STRINGS=40000

function spin_time() {
        COUNT=0
        TOTAL=0
        MAXIMUM=0
        COLLECT_DATA="/tmp/$1.log"
        FILE1="/tmp/$1.txt"
        FILE2="/tmp/$1_result.txt"
        chown zabbix:zabbix /tmp/$1.log
        chmod g+w /tmp/$1.log
        chown zabbix:zabbix /tmp/$1.txt
        chmod g+w /tmp/$1.txt
        chown zabbix:zabbix /tmp/$1_result.txt
        chmod g+w /tmp/$1_result.txt


        LOCAL_MINS_NOW=$(date +'%H:%M:%S')
        LOCAL_MINS_PREV=$(date -d "1 min ago" +'%H:%M:%S')

        DATA_COLLECTION=$(tail -n $STRINGS $LOG_FILE | grep "message processed" | awk -F"|"  -v awkvar="$1" '{if (($5==awkvar)) {print substr($1,12,8),$8}}' > $COLLECT_DATA)
        SPIN_TIMES=$(sed -n "/$LOCAL_MINS_PREV/,/$LOCAL_MINS_NOW/p" $COLLECT_DATA | awk -F"  " '{print $2}')
        echo $SPIN_TIMES > /tmp/$1.txt
        sed 's/\s\+/\n/g' /tmp/$1.txt > /tmp/$1_result.txt
        MIN=$(datamash min 1 < /tmp/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        MAX=$(datamash max 1 < /tmp/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        MEDIAN=$(datamash median 1 < /tmp/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        AVERAGE=$(datamash mean 1 < /tmp/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        q1=$(datamash q1 1 < /tmp/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        q3=$(datamash q3 1 < /tmp/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')

       
        for i in $SPIN_TIMES; do
                let "TOTAL+=$i"
                let "COUNT+=1"
        done

        if (($COUNT != 0)) ;then
                JSON_STRING='{"minimum":"'"$MIN"'","maximum":"'"$MAX"'","median":"'"$MEDIAN"'","average":"'"$AVERAGE"'","q1":"'"$q1"'","q3":"'"$q3"'"}'
                echo $JSON_STRING
        else    echo '{"minimum":"0","maximum":"0","median":"0","average":"0","q1":"0","q3":"0"}'
       
        fi

}



function spin_time_total() {
        COUNT=0
        TOTAL=0
        MAXIMUM=0
        COLLECT_DATA="/tmp/total.log"
        FILE1="/tmp/total.txt"
        FILE2="/tmp/total_result.txt"
        chown zabbix:zabbix /tmp/total.log
        chmod g+w /tmp/total.log
        chown zabbix:zabbix /tmp/total.txt
        chmod g+w /tmp/total.txt
        chown zabbix:zabbix /tmp/total_result.txt
        chmod g+w /tmp/total_result.txt


        LOCAL_MINS_NOW=$(date +'%H:%M:%S')
        LOCAL_MINS_PREV=$(date -d "1 min ago" +'%H:%M:%S')

        DATA_COLLECTION=$(tail -n $STRINGS $LOG_FILE | grep "message processed" | awk -F"|"   '{print substr($1,12,8),$8}' > $COLLECT_DATA)
        SPIN_TIMES=$(sed -n "/$LOCAL_MINS_PREV/,/$LOCAL_MINS_NOW/p" $COLLECT_DATA | awk -F"  " '{print $2}')
        echo $SPIN_TIMES > /tmp/total.txt
        sed 's/\s\+/\n/g' /tmp/total.txt > /tmp/total_result.txt
        MIN=$(datamash min 1 < /tmp/total_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        MAX=$(datamash max 1 < /tmp/total_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        MEDIAN=$(datamash median 1 < /tmp/total_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        AVERAGE=$(datamash mean 1 < /tmp/total_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        q1=$(datamash q1 1 < /tmp/total_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        q3=$(datamash q3 1 < /tmp/total_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')

       
        for i in $SPIN_TIMES; do
                let "TOTAL+=$i"
                let "COUNT+=1"
        done

        if (($COUNT != 0)) ;then
                JSON_STRING='{"minimum":"'"$MIN"'","maximum":"'"$MAX"'","median":"'"$MEDIAN"'","average":"'"$AVERAGE"'","q1":"'"$q1"'","q3":"'"$q3"'"}'
                echo $JSON_STRING
        else    echo '{"minimum":"0","maximum":"0","median":"0","average":"0","q1":"0","q3":"0"}'
       
        fi

}

case "$1" in
        0)
            spin_time_total
            ;;
        *)
            spin_time $1
            ;;
esac
