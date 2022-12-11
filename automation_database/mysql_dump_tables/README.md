# Backup MySQL tables 

### Skills summary:
- **#bash**
- **#aws**
- **#mysql**

### Requirements
- AWS credentials in `~/.aws/credentials`
- MySQL credentials in `~/.my.cnf`
```sh
[client]
user="username"
password="password"
```
### Description:
Script `mysqldump_few_tables.sh`:
1. Create directory with date for dump.
2. Creates mysql dump for requered tables in **gzip -9**
3. Copy dump file to aws s3
4. Rotate dumps in workdir after 10 days
