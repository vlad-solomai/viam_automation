#!/bin/bash

status=`curl --connect-time 3 -s  http://wallet/rgs/rest/realitycheck/sadmin/sessionBalance| grep -o success`

if [ "$status" == "success" ]; then
    # OK
    echo 1
else
    # ERROR
    echo 0
fi
