#!/bin/bash

mysql_env=${ENVIRONMENT}
mysql_host=${MYSQL_HOST}
mysql_database=${MYSQL_DB}

# create dump for the table
echo -e "Creating dump for ${ARCHIVE_TABLE} tables\n"
echo "dump_${ARCHIVE_TABLE}_table.sql"
$(mysqldump --defaults-file=~/.my.cnf -h ${mysql_host} --single-transaction ${mysql_database} ${ARCHIVE_TABLE} | gzip -9 > dump_${ARCHIVE_TABLE}_table.sql)
echo -e "Done!\n"

# copy file to s3
aws s3 cp dump_${ARCHIVE_TABLE}_table.sql s3://backups/MYSQL/${mysql_env}/archive/
