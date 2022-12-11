# MySQL kill process
### Skills summary:
- **#bash**
- **#mysql**

### Requirements:
- MySQL credentials in `~/.my.cnf`
- **MYSQL_HOST** should be passed into script

 ### Description:
Script `mysql_kill_process.sh`:
1. Get id from information_schema.processlist.
2. Format id output in list format.
3. Get mysql query information about issued process id.
4. Remove issued process (query id).
