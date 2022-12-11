#!/bin/bash -e
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# List of variables
client_names="username"
source_dbs="db1 db2 db3 db4"
source_env_ip="1.1.1.1"
backups_dir="/mnt/data/pgdumps"

# Working environment
dump_dir=$(date +%F)
mkdir -p ${backups_dir}/${dump_dir}
cd ${backups_dir}/${dump_dir}

# Creating database dumps for client
for client in ${client_names}; do
    for db in ${source_client_dbs}; do
        PGPASSWORD=passwd pg_dump -h ${source_env_ip} -U username -Fc ${db}_${client} | gzip -9 > ${db}_${client}.pgdump.gz
        echo "Created dump ${backups_dir}/${dump_dir}/${db}_${client}.pgdump.gz"
    done
    echo "DBs Backup for ${client} client has been completed!"
    echo ""
done

# Rotate dumps, remove folders created more that 10 days ago
find ${backups_dir} -maxdepth 1 -type d -name "*" \! -newermt '-10 days' -exec rm -rf {} \;
