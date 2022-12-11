#!/bin/bash

LOG_FILE=/usr/local/openresty/nginx/logs/access.log
STRINGS=40000

function response_time() {
        COUNT=0
        TOTAL=0
        MAXIMUM=0
        COLLECT_DATA="/tmp/gr_response/$1.log"
        chown zabbix:zabbix /tmp/gr_response/$1.log
        chmod g+w /tmp/gr_response/$1.log


        FILE1="/tmp/gr_response/$1.txt"
        FILE2="/tmp/gr_response/$1_result.txt"
        chown zabbix:zabbix /tmp/gr_response/$1.log
        chmod g+w /tmp/gr_response/$1.log
        chown zabbix:zabbix /tmp/gr_response/$1.txt
        chmod g+w /tmp/gr_response/$1.txt
        chown zabbix:zabbix /tmp/gr_response/$1_result.txt
        chmod g+w /tmp/gr_response/$1_result.txt

        LOCAL_MINS_NOW=$(date +'%Y:%H:%M:%S')
        LOCAL_MINS_PREV=$(date -d "1 min ago" +'%Y:%H:%M:%S')

        #DATA_COLLECTION=$(tail -n $STRINGS $LOG_FILE | grep "gamingrealms" | grep "$1"| awk -F"-" '{if (($2==200)||($2==499)) {print $0}}' > $COLLECT_DATA)
        if [[ $1 != "gvc" ]] ;then
            DATA_COLLECTION=$(tail -n $STRINGS $LOG_FILE | grep "gamingrealms" | grep "$1"| awk -F"-" '{if (($2==200)||($2==499)) {print $0}}' > $COLLECT_DATA)
        else    DATA_COLLECTION=$(tail -n $STRINGS $LOG_FILE | grep "gamingrealms" | grep -v "operatorId"| awk -F"-" '{if (($2==200)||($2==499)) {print $0}}' > $COLLECT_DATA)
        fi
    RESPONSE_TIMES=$(sed -n "/$LOCAL_MINS_PREV/,/$LOCAL_MINS_NOW/p" $COLLECT_DATA | awk -F"-" '{print $3*1000}')

        echo $RESPONSE_TIMES > /tmp/gr_response/$1.txt
        sed 's/\s\+/\n/g' /tmp/gr_response/$1.txt > /tmp/gr_response/$1_result.txt
        MIN=$(datamash min 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        MAX=$(datamash max 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        MEDIAN=$(datamash median 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        AVERAGE=$(datamash mean 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        q1=$(datamash q1 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        q3=$(datamash q3 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')

       
        for i in $RESPONSE_TIMES; do
                let "TOTAL+=$i"
                let "COUNT+=1"
        done

        if (($COUNT != 0)) ;then
                JSON_STRING='{"minimum":"'"$MIN"'","maximum":"'"$MAX"'","median":"'"$MEDIAN"'","average":"'"$AVERAGE"'","q1":"'"$q1"'","q3":"'"$q3"'"}'
                echo $JSON_STRING
        else    echo '{"minimum":"0","maximum":"0","median":"0","average":"0","q1":"0","q3":"0"}'
       
        fi

}

function response_time_all() {
        COUNT=0
        TOTAL=0
        MAXIMUM=0
        COLLECT_DATA="/tmp/gr_response/$1.log"
        chown zabbix:zabbix /tmp/gr_response/$1.log
        chmod g+w /tmp/gr_response/$1.log


        FILE1="/tmp/gr_response/$1.txt"
        FILE2="/tmp/gr_response/$1_result.txt"
        chown zabbix:zabbix /tmp/gr_response/$1.log
        chmod g+w /tmp/gr_response/$1.log
        chown zabbix:zabbix /tmp/gr_response/$1.txt
        chmod g+w /tmp/gr_response/$1.txt
        chown zabbix:zabbix /tmp/gr_response/$1_result.txt
        chmod g+w /tmp/gr_response/$1_result.txt

        LOCAL_MINS_NOW=$(date +'%Y:%H:%M:%S')
        LOCAL_MINS_PREV=$(date -d "1 min ago" +'%Y:%H:%M:%S')

        
        DATA_COLLECTION=$(tail -n $STRINGS $LOG_FILE | grep "gamingrealms" |  awk -F"-" '{if (($2==200)||($2==499)) {print $0}}' > $COLLECT_DATA)
       
        RESPONSE_TIMES=$(sed -n "/$LOCAL_MINS_PREV/,/$LOCAL_MINS_NOW/p" $COLLECT_DATA | awk -F"-" '{print $3*1000}')

        echo $RESPONSE_TIMES > /tmp/gr_response/$1.txt
        sed 's/\s\+/\n/g' /tmp/gr_response/$1.txt > /tmp/gr_response/$1_result.txt
        MIN=$(datamash min 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        MAX=$(datamash max 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        MEDIAN=$(datamash median 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        AVERAGE=$(datamash mean 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        q1=$(datamash q1 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')
        q3=$(datamash q3 1 < /tmp/gr_response/$1_result.txt 2> /dev/null | awk -F"," '{print $1}' | awk -F"." '{print $1}')

       
        for i in $RESPONSE_TIMES; do
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
        gr_all_operators)
            response_time_all
            ;;
        *)
            response_time $1
            ;;
esac
