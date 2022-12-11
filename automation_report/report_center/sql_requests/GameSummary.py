from sys import argv
from . import date_convertor

operator_id = argv[1]
start_date = argv[2]
end_date = argv[3]
time_zone_start = argv[4]
time_zone_end = argv[5]
time_zone_interval = date_convertor.convert_timezone(start_date, time_zone_start, time_zone_end)
time_zone_interval_end = date_convertor.convert_timezone(end_date, time_zone_start, time_zone_end)
report_name = "gameSummaryReport"
tmp_game_cycle_table = "tmp_DGE_game_cycle"
tmp_transaction_table = "tmp_DGE_payment_journal"
transaction_table = "tx_payment_journal_historical"


drop_tmp_game_cycle_table = "DROP TABLE IF EXISTS {};".format(tmp_game_cycle_table)

create_tmp_game_cycle_table = """\
CREATE TABLE {} (
  ID BIGINT(16) NOT NULL AUTO_INCREMENT,
  game_cycle_id VARCHAR(256) NOT NULL,
  PRIMARY KEY (ID),
  INDEX dge_game_cycle_id (game_cycle_id ASC));
""".format(tmp_game_cycle_table)

insert_tmp_game_cycle_table = """\
INSERT INTO {0} (game_cycle_id)
SELECT
        distinct(game_cycle_id)
        FROM {1} pj
        LEFT JOIN tx_player p ON pj.to_player_id = p.player_id
        WHERE
            pj.from_player_id = 1
        AND p.operator_id = {2}
        AND pj.complete=1
        AND pj.payment_date >= date_add('{3}', interval '{5}' hour)
        AND pj.payment_date < date_add('{4}', interval '{6}' hour);
""".format(tmp_game_cycle_table, transaction_table, operator_id, start_date, end_date, time_zone_interval, time_zone_interval_end)

drop_tmp_transaction_table = "DROP TABLE IF EXISTS {};".format(tmp_transaction_table)

create_tmp_transaction_table = """\
CREATE TABLE {} (
      transaction_id bigint(20) NOT NULL AUTO_INCREMENT,
      from_player_id bigint(20) NOT NULL,
      to_player_id bigint(20) NOT NULL,
      amount bigint(20) DEFAULT NULL,
      payment_date datetime DEFAULT NULL,
      game_id bigint(20) NOT NULL,
      complete tinyint(4) DEFAULT NULL,
      game_cycle_id varchar(256) COLLATE utf8_bin DEFAULT NULL,
      cancelled tinyint(1) NOT NULL DEFAULT '0',
      PRIMARY KEY (transaction_id),
      KEY idx_payment_journal_hist_game_x (game_id),
      KEY idx_payment_journal_hist_from_player_x (from_player_id),
      KEY idx_payment_journal_hist_to_player_x (to_player_id),
      KEY idx_payment_journal_hist_payment_date_x (payment_date),
      KEY idx_payment_journal_hist_game_cycle_x (game_cycle_id));
""".format(tmp_transaction_table)

insert_tmp_transaction_table = """\
INSERT INTO {0}
SELECT
    pj.transaction_id,
    pj.from_player_id,
    pj.to_player_id,
    pj.amount,
    pj.payment_date,
    pj.game_id,
    pj.complete,
    pj.game_cycle_id,
    pj.cancelled
    FROM {1} c
    left join {2} pj on c.game_cycle_id=pj.game_cycle_id;
""".format(tmp_transaction_table, tmp_game_cycle_table, transaction_table)

report="""\
SELECT game_name as 'Game_Name',
        '{0}' AS 'Gaming_Date',
        COUNT(DISTINCT(game_cycle_id)) as 'Total Spins',
        REPLACE(FORMAT( SUM(bet)/100,2), ',', '') AS 'Total Wagered',
        REPLACE(FORMAT(SUM(win)/100,2), ',', '') AS 'Total Won',
        REPLACE(FORMAT(SUM(bet - win)/100,2), ',', '') AS 'Margin'
FROM (
    SELECT  g.game_name, p.username,
            pj.amount * er.exchange_rate AS bet,
            0 AS win,
            game_cycle_id,
            payment_date

    FROM {1} pj
    JOIN core_game g ON g.game_id = pj.game_id
    JOIN tx_player p ON pj.from_player_id = p.player_id
    JOIN core_currency c ON p.currency_id = c.currency_id
    JOIN core_exchange_rate er ON c.currency_id = er.currency_id
    WHERE er.rate_year = YEAR(pj.payment_date)
    AND er.rate_month = MONTH(pj.payment_date)
    AND pj.to_player_id = 1
    AND pj.complete=1
    AND pj.cancelled=0

    UNION ALL
    SELECT  g.game_name, p.username,
            0 AS bet,
            pj.amount * er.exchange_rate  AS win,
            game_cycle_id,
            payment_date

    FROM {1} pj
    JOIN core_game g ON g.game_id = pj.game_id
    JOIN tx_player p ON pj.to_player_id = p.player_id
    JOIN core_currency c ON p.currency_id = c.currency_id
    JOIN core_exchange_rate er ON c.currency_id = er.currency_id
    WHERE er.rate_year = YEAR(pj.payment_date)
    AND er.rate_month = MONTH(pj.payment_date)
    AND pj.from_player_id = 1
    AND pj.complete=1
    AND pj.cancelled=0
) as f
GROUP BY  game_name;
""".format(start_date, tmp_transaction_table)
