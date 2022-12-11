#!/bin/bash

status=`curl --connect-timeout 3 -m 5 -s $1/health | jq -r '.checks[].status'`

if [ "$status" == "UP" ]; then
    # OK
    echo 1
else
    # ERROR
    echo 0
fi
