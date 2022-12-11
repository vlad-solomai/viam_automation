#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# pass parameters into script
mysql_env="env_name"
mysql_host="db_hostname"
mysql_database="database_name"
mysql_tables=("table_1_" "table_2_")
dump_date=$(date +%F)

# check directory for dump, create if not exist
if [ ! -d ${mysql_env}/${dump_date} ]; then
    mkdir -p ${mysql_env}/${dump_date}
fi

# create dump for tables
for table in "${mysql_tables[@]}"; do
    table_list=$(mysql --defaults-file=~/.my.cnf -h ${mysql_host} -te "use ${mysql_database}; show tables like '${table}%'\G;" | grep "${table}" | awk -F ": "  '{print $2}' | tr "\n" " ")                 
    echo -e "Creating dump for ${table_list}tables\n"
    $(mysqldump --defaults-file=~/.my.cnf -h ${mysql_host} --single-transaction ${mysql_database} ${table_list} | gzip -9 > ${mysql_env}/${dump_date}/dump_${dump_date}_${table}table.sql)
    echo -e "Done!\n"
done

# copy file to s3
aws s3 cp ${mysql_env}/${dump_date} s3://backups/MYSQL/${mysql_env}/ --recursive

# Rotate dumps in workdir after 10 days
find ${mysql_env} -maxdepth 1 -type d -name "*" \! -newermt '-10 days' -exec rm -rf {}\;
