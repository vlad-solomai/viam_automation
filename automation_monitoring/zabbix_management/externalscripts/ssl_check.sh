#! /bin/bash
SERVER=$1
TIMEOUT=25
RETVAL=0
#TIMESTAMP=`echo | date`
TIMESTAMP=$(date)
if [ -z "$2" ]
then
PORT=443;
else
PORT=$2;
fi
EXPIRE_DATE=`echo | openssl s_client -connect $SERVER:$PORT -servername $SERVER 2>/dev/null | openssl x509 -noout -dates 2>/dev/null | grep notAfter | cut -d'=' -f2`
EXPIRE_SECS=`date -d "${EXPIRE_DATE}" +%s`
EXPIRE_TIME=$(( ${EXPIRE_SECS} - `date +%s` ))
if test $EXPIRE_TIME -lt 0
then
RETVAL=0
else
RETVAL=$(( ${EXPIRE_TIME} / 24 / 3600 ))
fi
 
echo "$TIMESTAMP | $SERVER:$PORT expires in $RETVAL days" >> /tmp/ssl_check.log
#echo ${RETVAL}
cat /tmp/ssl_check.log | grep $SERVER | tail -n1 | awk '{print $11}'
