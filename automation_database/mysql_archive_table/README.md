# Archive MySQL table
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
Script `mysql_archive_table.sh` archive old data of table:
1. Select data from TABLE in **csv** format.
2. Create gzip dump for ${START_DATE}.
3. Copy archive to s3 if not exists.
4. Delete data from database for ${START_DATE}.

### Output example for 2021-02-01 - 2021-02-03(not included):
```
Working range: from 2021-02-01 to 2021-02-02
Archive with data was created for 2021-02-01
table_2021-02-01.csv.gz file was already uploaded to S3: 2021-09-28 at 09:31:50
Total count of transaction: 0
All id from table were removed

Working range: from 2021-02-02 to 2021-02-03
Archive with data was created for 2021-02-02
Completed 8.1 KiB/8.1 KiB (82.4 KiB/s) with 1 file(s) remaining
upload: ENV/2021-02/table_2021-02-05.csv.gz to s3://backup.logs/ENV/mysql_archive/table/2021-02/ENV_table_2021-02-05.csv.gz
Total count of transaction: 243
Attempts were performed 0, next 1000 transaction_id(s)  will be deleted
set @startID:= (select id from table where payment_date >= '2021-02-02' and payment_date < '2021-02-03' order by id ASC limit 1); set @endID:= @startID + 1000; set @endTXID:= (select id from table where payment_date >= '2021-02-02' and payment_date < '2021-02-03' order by id DESC limit 1); delete from table where id>=@startID and id<@endID and id<=@endTXID;
All id from table were removed
```
