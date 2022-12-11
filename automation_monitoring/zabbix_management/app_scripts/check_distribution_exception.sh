#!/bin/bash

current_time=$(date -d '1 hour ago' '+%Y-%m-%dT%H-')
error_count=$(grep 'Exception' /home/glassfish/glassfish4/glassfish/domains/game/logs/server.log_${current_time}* | wc -l)
echo "$((${error_count}))"
