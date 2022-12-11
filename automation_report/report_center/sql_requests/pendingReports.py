from sys import argv
from . import date_convertor

operator_id = argv[1]
start_date = argv[2]
end_date = argv[3]
time_zone_start = argv[4]
time_zone_end = argv[5]
time_zone_interval = date_convertor.convert_timezone(start_date, time_zone_start, time_zone_end)
time_zone_interval_end = date_convertor.convert_timezone(end_date, time_zone_start, time_zone_end)
report_name = "pendingReport"


report="""\
select T1.Gaming_Date,T1.Operator_Name,T1.Patron,T1.Game_Name,T1.Game_Id,T1.Transaction_Id,T1.SessionRound_ID,T1.Transaction_start_date_and_time,T1.Status,T1.wager,if (T2.Win is null,0,T2.Win) as win from
(select
date_format('{0}','%Y-%m-%d') as Gaming_Date,
o.operator_name 'Operator_Name',
p.username as 'Patron',
g.game_name as 'Game_Name',
g.short_code as 'Game_Id',
pj.transaction_id as 'Transaction_Id',
pj.game_cycle_id as 'SessionRound_ID',
payment_date as 'Transaction_start_date_and_time',
'incomplete' as 'Status',
REPLACE(FORMAT((pj.amount * e.exchange_rate) /100  ,2), ',', '') as wager,
0 as win
from tx_payment_journal pj
left join tx_player_session s on pj.session_id=s.session_id
left join tx_player p on s.player_id=p.player_id
left join tx_completed_game_cycle c on pj.game_cycle_id=c.payment_reference
left join core_operator o on p.operator_id=o.operator_id
left join core_game g on pj.game_id=g.game_id
left join core_exchange_rate e on p.currency_id=e.currency_id
where pj.payment_date<= date_add('{0}', interval {2} hour) and p.operator_id={1}  and to_player_id = 1 and complete=1 and cancelled=0 and c.completed_tx_id is null and e.rate_year = date_format(payment_date,'%Y') and e.rate_month = date_format(payment_date,'%m'))
as T1
left join (select
date_format(@endDate,'%Y-%m-%d') as Gaming_Date,
o.operator_name 'Operator_Name',
p.username as 'Patron',
g.game_name as 'Game_Name',
g.short_code as 'Game_Id',
pj.transaction_id as 'Transaction_Id',
pj.game_cycle_id as 'SessionRound_ID',
payment_date as 'Transaction_start_date_and_time',
'incomplete' as 'Status',
0 as wager,
REPLACE(FORMAT((pj.amount * e.exchange_rate) /100  ,2), ',', '') as win

from tx_payment_journal pj
left join tx_player_session s on pj.session_id=s.session_id
left join tx_player p on s.player_id=p.player_id
left join tx_completed_game_cycle c on pj.game_cycle_id=c.payment_reference
left join core_operator o on p.operator_id=o.operator_id
left join core_game g on pj.game_id=g.game_id
left join core_exchange_rate e on p.currency_id=e.currency_id
where p.operator_id={1} and from_player_id =1 and c.completed_tx_id is null and e.rate_year = date_format(payment_date,'%Y') and e.rate_month = date_format(payment_date,'%m'))
as T2

on T1.SessionRound_ID=T2.SessionRound_ID;
""".format(start_date, operator_id, time_zone_interval)
