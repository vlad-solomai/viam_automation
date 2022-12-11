#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

ENVIRONMENT=${ENVIRONMENT}
MYSQL_REPLICA=${MYSQL_REPLICA}
MYSQL_DB=${MYSQL_DB}

GAME_NAME=${GAME_NAME}                                 # (replace space by "_")
GAME_ID=${GAME_ID}                                     # from DB by GAME_NAME
START_DATE=${START_DATE}
END_DATE=$(date +%Y-%m-%d --date="$START_DATE +1 day") # START_DATE + 1 day
OPERATOR_NAME=${OPERATOR_NAME}                         # (replace space by "_")
OPERATOR_ID=${OPERATOR_ID}                             # from DB by OPERATOR_NAME
TIME_ZONE_INTERVAL=${TIME_ZONE_INTERVAL}               # Difference betwwen UTC and EST for START_DATE (can be cnstant for the  first time)
TIME_ZONE_INTERVAL_END=${TIME_ZONE_INTERVAL_END}       # Difference betwwen UTC and EST for END_DATE (can be cnstant for the  first time)
EST=${EST}                                             # try to get the difference between time zones (can be cnstant for the  first time)
TRANSACTIONS_TABLE=${TRANSACTIONS_TABLE}               # try to get the difference between time zones (can be cnstant for the  first time)
TEMP_TABLE_GAME_CYCLE='tmp_transactional_report_game_cycle'
TEMP_TABLE_TRANSACTIONS='tmp_transactional_report_payment_journal'
TRANSACTIONS_TABLE='tx_payment_journal_historical'
S3_PATH="reports/transactional_reports/${ENVIRONMENT}/${OPERATOR_NAME}/${START_DATE}/"
REPORT_FILE="${ENVIRONMENT}_${OPERATOR_NAME}_${START_DATE}_${GAME_NAME}.csv"

# Temporary table query
SQL_CREATE_TEMP_TABLE="
SET @startDate := '${START_DATE}', @endDate := '${END_DATE}',@GAME_ID:='${GAME_ID}',@OPERATOR_ID:=${OPERATOR_ID}, @TIME_ZONE_INTERVAL:=${TIME_ZONE_INTERVAL}, @TIME_ZONE_INTERVAL_END:=${TIME_ZONE_INTERVAL_END}, @EST=${EST};

DROP TABLE IF EXISTS ${TEMP_TABLE_GAME_CYCLE};

CREATE TABLE ${TEMP_TABLE_GAME_CYCLE}(
  ID BIGINT(16) NOT NULL AUTO_INCREMENT,
  game_cycle_id VARCHAR(256) NOT NULL,
  PRIMARY KEY (ID),
  INDEX transactional_report_game_cycle_id (game_cycle_id ASC));

INSERT INTO ${TEMP_TABLE_GAME_CYCLE} (game_cycle_id)
SELECT
        distinct(game_cycle_id)
        FROM ${TRANSACTIONS_TABLE} pj
        LEFT JOIN tx_player p ON pj.to_player_id = p.player_id
        WHERE
            pj.from_player_id = 1
        AND p.operator_id = @OPERATOR_ID
        AND pj.complete=1
        AND pj.payment_date >= date_add(@startDate, interval @TIME_ZONE_INTERVAL hour)
        AND pj.payment_date < date_add(@endDate, interval @TIME_ZONE_INTERVAL_END hour);

DROP TABLE IF EXISTS ${TEMP_TABLE_TRANSACTIONS};

CREATE TABLE ${TEMP_TABLE_TRANSACTIONS} (
      transaction_id bigint(20) NOT NULL AUTO_INCREMENT,
      from_player_id bigint(20) NOT NULL,
      to_player_id bigint(20) NOT NULL,
      amount bigint(20) DEFAULT NULL,
      payment_date datetime DEFAULT NULL,
      game_id bigint(20) NOT NULL,
      complete tinyint(4) DEFAULT NULL,
      game_cycle_id varchar(256) COLLATE utf8_bin DEFAULT NULL,
      cancelled tinyint(1) NOT NULL DEFAULT '0',
      normalized_game_cycle_id bigint(20) DEFAULT NULL,
      PRIMARY KEY (transaction_id),
      KEY idx_transactional_report_game_x (game_id),
      KEY idx_transactional_report_from_player_x (from_player_id),
      KEY idx_transactional_report_to_player_x (to_player_id),
      KEY idx_transactional_report_payment_date_x (payment_date),
      KEY idx_transactional_report_game_cycle_x (game_cycle_id),
      KEY idx_transactional_report_normalized_game_cycle_x (normalized_game_cycle_id));

INSERT INTO ${TEMP_TABLE_TRANSACTIONS}
SELECT
    pj.transaction_id,
    pj.from_player_id,
    pj.to_player_id,
    pj.amount,
    pj.payment_date,
    pj.game_id,
    pj.complete,
    pj.game_cycle_id,
    pj.cancelled,
    n.normalized_game_cycle_id
    FROM ${TEMP_TABLE_GAME_CYCLE} c
    left join ${TRANSACTIONS_TABLE} pj on c.game_cycle_id=pj.game_cycle_id
    left join tx_normalized_game_cycle_key n on c.game_cycle_id=n.game_cycle_id;"


# Generate report query
SQL_GENERATE_REPORT="
SET @startDate := '${START_DATE}', @endDate := '${END_DATE}',@GAME_ID:='${GAME_ID}',@OPERATOR_ID:=${OPERATOR_ID}, @TIME_ZONE_INTERVAL:=${TIME_ZONE_INTERVAL}, @TIME_ZONE_INTERVAL_END:=${TIME_ZONE_INTERVAL_END}, @EST=${EST};

SELECT concat(T1.game_name,',') as 'game_name,', concat(T1.username,',') as 'username,', concat(T1.bet,',') as 'bet,', concat(T2.win,',') as 'win,', concat(T1.game_cycle_id,',') as 'game_cycle_id,',concat(if (T1.normalized_game_cycle_id is null,'',T1.normalized_game_cycle_id),',') as 'normalized_game_cycle_id,', concat(T1.payment_date,',') as 'UTC_time,', T1.EST_time from (
    (SELECT         g.game_name, p.username,
    pj.amount/100 AS bet,
    0 AS win,
    transaction_id,
    pj.game_cycle_id,
    pj.normalized_game_cycle_id,
    pj.payment_date,
    date_add(payment_date, interval @EST hour) as 'EST_time'

    FROM ${TEMP_TABLE_TRANSACTIONS} pj
    LEFT JOIN core_game g ON g.game_id = pj.game_id
    LEFT JOIN tx_player p ON pj.from_player_id = p.player_id
    WHERE
    pj.to_player_id = 1
    AND pj.game_id = @GAME_ID
    AND p.operator_id = @OPERATOR_ID

    ) as T1,

    (SELECT         g.game_name, p.username,
    0 AS bet,
    pj.amount/100 AS win,
    transaction_id,
    pj.game_cycle_id,
    null as normalized_game_cycle_id,
    pj.payment_date,
    date_add(payment_date, interval -@EST hour) as 'EST_time'

    FROM ${TEMP_TABLE_TRANSACTIONS} pj
    LEFT JOIN core_game g ON g.game_id = pj.game_id
    LEFT JOIN tx_player p ON pj.to_player_id = p.player_id

    WHERE
    pj.from_player_id = 1
    AND pj.game_id = @GAME_ID
    AND p.operator_id = @OPERATOR_ID

    ) as T2)
where T1.game_cycle_id=T2.game_cycle_id;"

date
echo "Exporting Transactional Level Report:"
echo "START_DATE: ${START_DATE}"
echo "END_DATE: ${END_DATE}"
echo "SQL_CREATE_TEMP_TABLE: ${SQL_CREATE_TEMP_TABLE}"
echo "SQL_GENERATE_REPORT: ${SQL_GENERATE_REPORT}"

date
echo "Inserting data for one day to 'tmp_tx_payment_journal_one_day' table"
mysql --defaults-file=~/.my.cnf -h ${MYSQL_REPLICA} -P 3306 -A -D ${MYSQL_DB} -N -e "${SQL_CREATE_TEMP_TABLE}"

date
if [[ ! -e "${REPORT_FILE}" ]] || [[ -s "${REPORT_FILE}" ]]; then
    echo "Generating Transactional Level report"
    mysql --defaults-file=~/.my.cnf -h ${MYSQL_REPLICA} -P 3306 -A -D ${MYSQL_DB} -e "${SQL_GENERATE_REPORT}" | sed 's/\t//g' > ${REPORT_FILE}

    echo "Transactional Level Report was successfully generated from secondary '${MYSQL_REPLICA}' database"
else
    echo "File does not exist or not empty"
fi

date
zip ${REPORT_FILE}.zip ${REPORT_FILE}
aws s3 cp ${REPORT_FILE}.zip s3://${S3_PATH}
