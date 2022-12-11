#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# pass parameter ${MYSQL_HOST} into script
mysql_host=$1

sql_get_id="select id from information_schema.processlist where host like '3.3.3.3:%' and time >300\G;"

sql_id_output=$(mysql --defaults-file=~/.my.cnf -h ${mysql_host} -e "${sql_get_id}" | grep "id" | awk -F ": " '{print $2}' | tr "\n" " ")

echo -e "\nList of queries with time more than 5 mins: ${sql_id_output}\n"

for query_id in ${sql_id_output}; do
    sql_get_info="select info from information_schema.processlist where id=${query_id}\G;"
    sql_info_output=$(mysql --defaults-file=~/.my.cnf -h ${mysql_host} -e "${sql_get_info}" | sed "1 d")
    echo -e "Query was killed:\n ${sql_info_output}\n"
    $(mysql --defaults-file=~/.my.cnf -h ${mysql_host} -e "kill ${query_id}")
done

echo -e "\nWork with issued queries was finished\n"
