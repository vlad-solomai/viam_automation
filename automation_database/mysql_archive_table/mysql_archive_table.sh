#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

MYSQL_PRIMARY=${MYSQL_PRIMARY}
MYSQL_DB=${MYSQL_DB}
ENV=${ENVIRONMENT}
MYSQL_TABLE=${MYSQL_TABLE}
S3_PATH="s3://backup.logs"
ARC_START=${ARCHIVE_START_DATE}
ARC_END=${ARCHIVE_FINISH_DATE}

while [[ ${ARC_START} != ${ARC_END} ]]; do
    START_DATE=${ARC_START}
    FINISH_DATE=$(date +%Y-%m-%d -d "$ARC_START +1 day")
    MONTH=$(date +%Y-%m -d "$START_DATE")
    echo "Working range: from ${START_DATE} to ${FINISH_DATE}"

    # Check directory for dump, create locally if not exist:
    if [[ ! -d ${ENV}/${MONTH} ]]; then
        mkdir -p ${ENV}/${MONTH}
    fi

    # Create gzip dump for ${START_DATE}:
    SQL_DATA_ACR="SELECT * from ${MYSQL_TABLE} pj
                  WHERE pj.transaction_id>=(SELECT transaction_id FROM ${MYSQL_TABLE} where payment_date >= '${START_DATE}' limit 1)
                  AND pj.transaction_id<(SELECT transaction_id FROM ${MYSQL_TABLE} where payment_date >= '${FINISH_DATE}' limit 1);"
    LOCAL_ARC_DIR="${ENV}/${MONTH}"
    S3_ARC_DIR="${ENV}/mysql_archive/${MYSQL_TABLE}/${MONTH}"
    ARC_FILE="${ENV}_${MYSQL_TABLE}_${START_DATE}.csv.gz"
    GET_RESULT=$(mysql --defaults-file=~/.my.cnf -h ${MYSQL_PRIMARY} -P 3306 -D ${MYSQL_DB} -A -udw -e "$SQL_DATA_ACR" | gzip -9 > ${LOCAL_ARC_DIR}/${ARC_FILE})
    echo "Archive with data was created for $START_DATE"

    # Copy archive to s3 if not exists:
    S3_TIME=$(aws s3 ls ${S3_PATH}/${S3_ARC_DIR}/${ARC_FILE} | awk '{print $1, "at", $2}')
    S3_FILE=$(aws s3 ls ${S3_PATH}/${S3_ARC_DIR}/${ARC_FILE} | awk '{print $4}')
    if [[ ${S3_FILE} == ${ARC_FILE} ]]; then
        echo "${S3_FILE} file was already uploaded to S3: ${S3_TIME}"
    else
        aws s3 cp ${LOCAL_ARC_DIR}/${ARC_FILE} ${S3_PATH}/${S3_ARC_DIR}/${ARC_FILE}
    fi

    # Delete data from database for ${START_DATE}:
    COUNT=0
    CHUNK=1000
    SQL_TRZ_COUNT="select count(*) from ${MYSQL_TABLE} where payment_date >= '${START_DATE}' and payment_date < '${FINISH_DATE}';"
    TRZ_COUNT=$(mysql --defaults-file=~/.my.cnf -h ${MYSQL_PRIMARY} -P 3306 -D ${MYSQL_DB} -N -udw -e "$SQL_TRZ_COUNT")
    echo "Total count of transaction: ${TRZ_COUNT}"
    while [[ ${COUNT} -lt ${TRZ_COUNT} ]] || [[ ${COUNT} -eq ${TRZ_COUNT} ]]; do
        TRZ_CHECK=$(mysql --defaults-file=~/.my.cnf -h ${MYSQL_PRIMARY} -P 3306 -D ${MYSQL_DB} -N -udw -e "$SQL_TRZ_COUNT")
        if [[ ${TRZ_CHECK} -eq 0 ]]; then
            echo "All transaction_id from ${MYSQL_TABLE} were removed"
            break
        else
            echo "Attempts were performed ${COUNT}, next ${CHUNK} transaction_id(s)  will be deleted"
            SQL_DATA_DEL="
                set @startID:= (select transaction_id from ${MYSQL_TABLE} where payment_date >= '${START_DATE}' and payment_date < '${FINISH_DATE}' order by transaction_id ASC limit 1);
                set @endID:= @startID + ${CHUNK};
                set @endTXID:= (select transaction_id from ${MYSQL_TABLE} where payment_date >= '${START_DATE}' and payment_date < '${FINISH_DATE}' order by transaction_id DESC limit 1);
                delete from ${MYSQL_TABLE} where transaction_id>=@startID and transaction_id<@endID and transaction_id<=@endTXID;"
            echo $SQL_DATA_DEL
            DEL_RESULT=$(mysql --defaults-file=~/.my.cnf -h ${MYSQL_PRIMARY} -P 3306 -D ${MYSQL_DB} -A -udw -e "$SQL_DATA_DEL")
        fi
        ((COUNT++))
    done
    ARC_START=${FINISH_DATE}
done
