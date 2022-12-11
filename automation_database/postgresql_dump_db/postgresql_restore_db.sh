#!/bin/bash
set -x
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

client="username"
export PGPASSWORD="db_user"
db_user_name="db_user"
dbs=("db1" "db2" "db3")

for db in "${dbs[@]}"; do
    pg_dump -c -O -x --if-exists -d "$db" -h dbhost -U "${db_user_name}" -f dumps/${db.txt}
    psql -d "${db}" -h dbhost -U "${db_user_name}" -f dumps/${db.txt}
done
