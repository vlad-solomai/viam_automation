#!/bin/bash

status=`curl --connect-timeout 3 -I -s $1 | grep -no '200 OK'`

if [ "$status" == "1:200 OK" ]; then
    # OK
    echo 1
else
    # ERROR
    echo 0
fi
