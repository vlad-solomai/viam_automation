# Create transactional report
### Skills summary:
- **#bash**
- **#mysql**
- **aws**

### Requirements
- AWS credentials in `~/.aws/credentials`
- MySQL credentials in `~/.my.cnf`
- Date format **yyyy-MM-dd**
```sh
[client]
user="username"
password="password"
```
### Description:
Script `transactional_report.sh`:
1. Create temporary table
2. Collect information about transactional data
3. Generate transactional report
4. Copy archive to s3

### Output example for 2021-02-01 - 2021-02-03(not included):
```
Mon Jun 14 14:21:01 UTC 2021

Exporting Transactional Level Report:
START_DATE: 2021-06-14
END_DATE: 2021-06-15
SQL_CREATE_TEMP_TABLE: 
SET @startDate := '2021-06-14', @endDate := '2021-06-15',@OPERATOR_ID:=183, @TIME_ZONE_INTERVAL:=10, @TIME_ZONE_INTERVAL_END:=10, @EST=-4;

Mon Jun 14 14:21:01 UTC 2021

Inserting data for one day to 'tmp_tx_payment_journal_one_day' table

Mon Jun 14 14:21:08 UTC 2021

Generating Transactional Level report

Transactional Level Report was successfully generated from secondary '172.16.24.12' database

Mon Jun 14 14:21:08 UTC 2021
  adding: MI_Betmgm_MI_2021-06-14_Golden_Wins.csv (stored 0%)
Completed 228 Bytes/228 Bytes (432 Bytes/s) with 1 file(s) remaining
upload: ./MI_Betmgm_MI_2021-06-14_Golden_Wins.csv.zip to s3://reports/MI/Betmgm_MI/2021-06-14/MI_Betmgm_MI_2021-06-14_Golden_Wins.csv.zip
```
