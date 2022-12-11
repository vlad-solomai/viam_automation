#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# pass parameters into script
SOURCE_HOST="source_hostname"
SOURCE_DATABASE="ENV1"

TARGET_HOST="target_hostname"
TARGET_DATABASE="ENV2"

TABLE_NAME=("table1" "table2")

function table_dump () {
    echo -e "\n"
    # select data of TABLE from SOURCE_HOST
    SQL_QUERY="select ${SQL_FIELD} from $1;"
    mysql --defaults-file=~/.my1.cnf -h ${SOURCE_HOST} -P 3306 -e "use ${SOURCE_DATABASE}; ${SQL_QUERY};" | sed '1d' | sort -n > $1_${SOURCE_DATABASE}.csv
    echo "Select query of '$1' table from '${SOURCE_DATABASE}' database completed"
    
    # select data of TABLE from TARGET_HOST
    mysql --defaults-file=~/.my2.cnf -h ${TARGET_HOST} -P 3306 -e "use ${TARGET_DATABASE}; select * from $1;" | sed '1d' | sort -n > $1_${TARGET_DATABASE}.csv
    echo "Select query of '$1' table from '${TARGET_DATABASE}' database completed"
    
    echo "Collecting info about differences"
    diff -u $1_${TARGET_DATABASE}.csv $1_${SOURCE_DATABASE}.csv | grep -E "^(\+|\-)" > diff_$1_all_data.txt
    diff -u $1_${TARGET_DATABASE}.csv $1_${SOURCE_DATABASE}.csv | grep -E "^\+" | sed -E 's/^\+//' | sed '1d' > diff_${SOURCE_DATABASE}_$1.txt
    diff -u $1_${TARGET_DATABASE}.csv $1_${SOURCE_DATABASE}.csv | grep -E "^\-" | sed -E 's/^\-//' | sed '1d' > diff_${TARGET_DATABASE}_$1.txt
    
    cp -p diff_${SOURCE_DATABASE}_$1.txt insert_${SOURCE_DATABASE}_$1.txt
    
    source_id=`awk '{print $1}' diff_${SOURCE_DATABASE}_$1.txt`
    target_id=`awk '{print $1}' diff_${TARGET_DATABASE}_$1.txt`

    echo "DONE!"
    
    # check the same ID in TARGET and SOURCE data
    for s_id in ${source_id}; do            
        # update info in TARGET_DATABASE if indexes are the same
        for r_id in ${target_id}; do
            if [ ${s_id} -eq ${r_id} ]; then             
                
                if [ $1 = "table1" ]; then
                    target_name=`grep -E "^${r_id}\s" diff_${TARGET_DATABASE}_$1.txt | awk '{$1=""; print $0}' | sed -E 's/^ //'`                
                    source_name=`grep -E "^${s_id}\s" diff_${SOURCE_DATABASE}_$1.txt | awk '{$1=""; print $0}' | sed -E 's/^ //'`
                                        
                    echo "Working with '$1' table"
                    echo "Name '${target_name}' should be changed to '${source_name}'"
                    echo "UPDATE $1 SET name='${source_name}' WHERE id=${s_id};"
                    mysql --defaults-file=~/.my2.cnf -h ${TARGET_HOST} -P 3306 -e "use ${TARGET_DATABASE}; UPDATE $1 SET name='${source_name}' WHERE id=${s_id};"
                    sed -i "/${source_name}/d" insert_${SOURCE_DATABASE}_$1.txt
                   
                    # insert info in TARGET_DATABASE if indexes are not exist
                    insert_id=`awk '{print $1}' insert_${SOURCE_DATABASE}_$1.txt`

                elif [ $1 = "table2" ]; then
                    stage_active=`grep -E "^${s_id}\s" diff_${SOURCE_DATABASE}_$1.txt | awk '{print $NF}'`
                    stage_name=`grep -E "^${s_id}\s" diff_${SOURCE_DATABASE}_$1.txt | awk '{$1=""; print $0}' | sed -E 's/^ //' | sed -E "s/ ${stage_active}//"`
                    
                    echo "Working with '$1' table"
                    echo "UPDATE $1 SET name='${stage_name}', active=${stage_active} WHERE id=${s_id};"
                    mysql --defaults-file=~/.my2.cnf -h ${TARGET_HOST} -P 3306 -e "use ${TARGET_DATABASE}; UPDATE $1 SET name='${stage_name}', active=${stage_active} WHERE id=${s_id};"
                    sed -i "/${stage_name}/d" insert_${SOURCE_DATABASE}_$1.txt  
                fi                
            fi
        done              
    done
    
    echo -e "\n"
    # insert info in TARGET_DATABASE if indexes are not exist
    insert_id=`awk '{print $1}' insert_${SOURCE_DATABASE}_$1.txt`
        
    for data in ${insert_id}; do        
        if [ $1 = "table1" ]; then
            insert_name=`grep -E "^${data}\s" insert_${SOURCE_DATABASE}_$1.txt | awk '{$1=""; print $0}' | sed -E 's/^ //'`
            echo "'${insert_name}' should be added into '${1}'"
            echo "INSERT INTO $1 (id,name) VALUES (${data},'${insert_name}');"
            mysql --defaults-file=~/.my2.cnf -h ${TARGET_HOST} -P 3306 -e "use ${TARGET_DATABASE}; INSERT INTO $1 (id,name) VALUES (${data},'${insert_name}');"
            
        elif [ $1 = "table2" ]; then
            insert_active=`grep -E "^${data}\s" insert_${SOURCE_DATABASE}_$1.txt | awk '{print $NF}'`
            insert_name=`grep -E "^${data}\s" insert_${SOURCE_DATABASE}_$1.txt | awk '{$1=""; print $0}' | sed -E 's/^ //' | sed -E "s/ ${insert_active}//"`
            echo "'${insert_name}' should be added into '${1}'"
            echo "INSERT INTO $1 (id,name,active) VALUES (${data},'${insert_name}','${insert_active}');"
            mysql --defaults-file=~/.my2.cnf -h ${TARGET_HOST} -P 3306 -e "use ${TARGET_DATABASE}; INSERT INTO $1 (id,name,active) VALUES (${data},'${insert_name}','${insert_active}');"
        fi
    done
}

for table in "${TABLE_NAME[@]}"; do
    if [ ${table} = "table1" ]; then
        SQL_FIELD="a_id, a_name"
        table_dump "${table}"
    elif [ ${table} = "table2" ]; then
        SQL_FIELD="b_id, b_name, active"
        table_dump "${table}"
    fi
done

echo "All queries completed"
