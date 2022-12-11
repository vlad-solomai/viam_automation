from sys import argv
from . import date_convertor


operator_id = argv[1]
start_date = argv[2]
end_date = argv[3]
time_zone_start = argv[4]
time_zone_end = argv[5]
time_zone_interval = date_convertor.convert_timezone(start_date, time_zone_start, time_zone_end)
time_zone_interval_end = date_convertor.convert_timezone(end_date, time_zone_start, time_zone_end)
report_name = "voidReport"


report="""\
SELECT
 date(date_add(payment_date, interval '{3}' hour)) as 'Gaming_Date',
 o.operator_name as 'Operator_Name',
 p.username as 'Patron',
 g.game_name as 'Game_Name',
 g.short_code as 'Game_Id',
 pj.transaction_id as 'Transaction_Id',
 pj.game_cycle_id as 'SessionRound_ID',
 date_add(payment_date, interval '{3}' hour) as 'Transaction_start_date_and_time',
 date_add(payment_date, interval '{3}' hour) as 'Transaction_end_date_and_time',
CASE
  WHEN pj.from_player_id!=1 THEN REPLACE(FORMAT(pj.amount/100  ,2), ',', '')
    ELSE '0'
  END as Amount_of_wager,
CASE
  WHEN pj.from_player_id=1 THEN REPLACE(FORMAT(pj.amount/100  ,2), ',', '')
    ELSE '0'
  END as Amount_of_win,
CASE
  WHEN reason is null THEN 'unsuccessful debit'
    ELSE reason
  END as Reason_for_void,

 'system' as Voided_by

from (select transaction_id,payment_date,from_player_id,game_id,game_cycle_id,amount from tx_payment_journal_historical where payment_date>=date_add('{0}', interval '{3}' hour) and payment_date <date_add('{1}', interval '{4}' hour) and to_player_id=1 and cancelled=1
union all
select transaction_id,payment_date,from_player_id,game_id,game_cycle_id,amount from tx_payment_journal where payment_date>=date_add('{0}', interval '{3}' hour) and payment_date <date_add('{1}', interval '{4}' hour) and to_player_id=1 and complete=1 and cancelled=1) as pj
left join core_game g ON g.game_id = pj.game_id
left join tx_player p on pj.from_player_id=p.player_id
left join core_operator o ON p.operator_id = o.operator_id
left join tx_cancelled_payment cp on pj.transaction_id=cp.transaction_id
where p.operator_id='{2}';
""".format(start_date, end_date, operator_id, time_zone_interval, time_zone_interval_end)
