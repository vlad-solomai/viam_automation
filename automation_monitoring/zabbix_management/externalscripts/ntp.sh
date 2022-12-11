#!/bin/bash

VERSION="1.0"
function usage()
{
echo "ntpcheck version: $VERSION"
echo "usage:"
echo " $0 jitter - Check ntp jitter delay"
echo " $0 offset - Check ntp offset"
echo " $0 delay - Check ntp delay"
}

########
# Main #
########
if [[ $# != 1 ]];then
#No Parameter
usage
exit 0
fi

case "$1" in
'jitter')
value=`ntpq -pn 127.0.0.1 | /usr/bin/awk 'BEGIN { jitter=0 } $1 ~/\*/ { jitter=$10 } END { print jitter }'`
rval=$?;;

'offset')
value=`ntpq -pn 127.0.0.1 | /usr/bin/awk 'BEGIN { offset=0 } $1 ~/\*/ { offset=$9 } END { print offset }'`
rval=$?;;

'delay')
value=`ntpq -pn 127.0.0.1 | /usr/bin/awk 'BEGIN { delay=0 } $1 ~/\*/ { delay=$8 } END { print delay }'`
rval=$?;;

'health')
primary=`ntpq -pn 127.0.0.1 | grep ^\* |grep -v grep | wc -l`
rval=$?
if [ "${primary}" -eq "1" ] ; then
value="1"
else
value="0"
fi
;;

*)
usage
exit 1;;
esac

if [ "$rval" -eq 0 -a -z "$value" ]; then
rval=1
fi

if [ "$rval" -ne 0 ]; then
echo "ZBX_NOTSUPPORTED"
fi
echo $value
