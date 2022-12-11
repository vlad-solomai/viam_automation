# PostgreSQL dump 
### Skills summary:
- **#bash**
- **#postgresql**

### Description:
Script `postgresql_dump_db.sh` create dump of databases:
1. Create directory with date for dump.
2. Creating postgresql dump for requered databases in gzip -9.
3. Rotate dumps in workdir after 10 days.

Script `postgresql_restore_db.sh` restore database from dump.
