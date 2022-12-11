#!/bin/bash 

# New version of failed requests check script. Return count of failed requests for last minute 

LOG_FILE=/usr/local/openresty/nginx/logs/access.log

# 502
function failed_502_count()
{

COLLECT_DATA="/tmp/$1_$2.log"
chown zabbix:zabbix /tmp/$1_$2.log
chmod g+w /tmp/$1_$2.log
COUNT=0
HOURS=$(date +"%H")
MINUTES=$(date +"%M")
DATA_COLLECTION=$(tail -n 40000 $LOG_FILE | awk 'BEGIN {FS="-"; RS="\n"} {if ($2==502){print $0}}' > $COLLECT_DATA )
FAILS=$(cat $COLLECT_DATA | awk -v h=$HOURS 'BEGIN {FS=":"; RS="\n"} {if ($2==h){print $0}}' | awk -v m=$MINUTES 'BEGIN {FS=":"; RS="\n"} {if ($3==m){print $0}}' | wc -l)

echo $FAILS
}

# 499
function failed_499_count()
{

COLLECT_DATA="/tmp/$1_$2.log"
chown zabbix:zabbix /tmp/$1_$2.log
chmod g+w /tmp/$1_$2.log
COUNT=0
HOURS=$(date +"%H")
MINUTES=$(date +"%M")
DATA_COLLECTION=$(tail -n 40000 $LOG_FILE | awk 'BEGIN {FS="-"; RS="\n"} {if ($2==499){print $0}}' > $COLLECT_DATA )
FAILS=$(cat $COLLECT_DATA | awk -v h=$HOURS 'BEGIN {FS=":"; RS="\n"} {if ($2==h){print $0}}' | awk -v m=$MINUTES 'BEGIN {FS=":"; RS="\n"} {if ($3==m){print $0}}' | wc -l)

echo $FAILS
}

# 500
function failed_500_count()
{

COLLECT_DATA="/tmp/$1_$2.log"
chown zabbix:zabbix /tmp/$1_$2.log
chmod g+w /tmp/$1_$2.log
COUNT=0
HOURS=$(date +"%H")
MINUTES=$(date +"%M")
DATA_COLLECTION=$(tail -n 40000 $LOG_FILE | awk 'BEGIN {FS="-"; RS="\n"} {if ($2==500){print $0}}' > $COLLECT_DATA )
FAILS=$(cat $COLLECT_DATA | awk -v h=$HOURS 'BEGIN {FS=":"; RS="\n"} {if ($2==h){print $0}}' | awk -v m=$MINUTES 'BEGIN {FS=":"; RS="\n"} {if ($3==m){print $0}}' | wc -l)

echo $FAILS
}
# LONG RESPONSE
function long_request_count()
{

COUNT=0
STRINGS=40000

COLLECT_DATA="/tmp/$1_$2.log"
chown zabbix:zabbix /tmp/$1_$2.log
chmod g+w /tmp/$1_$2.log


    LOCAL_MINS_NOW=$(date +'%Y:%H:%M:%S')
    LOCAL_MINS_PREV=$(date -d "1 min ago" +'%Y:%H:%M:%S')

    DATA_COLLECTION=$(tail -n $STRINGS $LOG_FILE |  awk -F"-" '{if ($3>10) {print $0} }' > $COLLECT_DATA)
    COUNT=$(sed -n "/$LOCAL_MINS_PREV/,/$LOCAL_MINS_NOW/p" $COLLECT_DATA | wc -l)
    echo $COUNT

}

# LONG RESPONSE RUSH

function long_request_count_rush()
{
COUNT=0
STRINGS=40000

COLLECT_DATA="/tmp/$1_$2.log"

    LOCAL_MINS_NOW=$(date +'%Y:%H:%M:%S')
    LOCAL_MINS_PREV=$(date -d "1 min ago" +'%Y:%H:%M:%S')

    DATA_COLLECTION=$(tail -n $STRINGS $LOG_FILE | grep "rush-pa" | awk -F"-" '{if ($3>10) {print $0} }' > $COLLECT_DATA)
    COUNT=$(sed -n "/$LOCAL_MINS_PREV/,/$LOCAL_MINS_NOW/p" $COLLECT_DATA | wc -l)
    echo $COUNT

}


case "$1" in
        502)
                failed_502_count $1
                ;;
        499)
                failed_499_count $1
                ;;
        500)
                failed_500_count $1
                ;;
        10)
                long_request_count $1
                ;;
        rush_10)
                long_request_count_rush $1
                ;;
        *)
                echo $"Usage $0 {502|499|500|10|rush_10}"
                exit
esac
