#!/bin/bash
status=`curl --connect-timeout 3 -s $1/health | jq -r '.checks[].status'`
if [ "$status" == "UP" ]; then
    # OK
    echo 1
elif [ "$status" == "DOWN" ]; then
    # ERROR     
    echo 0 && exit 2
else
    # ERROR
    echo 2 && exit 3
fi
