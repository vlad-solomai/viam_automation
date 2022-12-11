# Synchronize MySQL tables 
### Skills summary:
- **#bash**
- **#mysql**

### Requirements
- MySQL credentials in `~/.my.cnf`
```sh
[client]
user="username"
password="password"
```
### Description:
Script `sync_tables_csv.sh` synchronize list of different tables:
1. Select data of TABLEs from **SOURCE_HOST** and **TARGET_HOST** in **csv** format.
2. Collecting info about differences.
3. Check the same **ID** in **TARGET** and **SOURCE** data.
4. Update info in **TARGET_DATABASE** if indexes are the same.
5. Insert info in **TARGET_DATABASE** if indexes are not exist
6. Insert info in **TARGET_DATABASE** if indexes are not exist
