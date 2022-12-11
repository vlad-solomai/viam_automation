# Deploy Game Client
### Skills summary:
- **#python3**
- **#mysql**
- **#aws**
- **#csv**

### Requirements
- AWS credentials in `~/.aws/credentials`
- MySQL credentials in `/var/lib/jenkins/mysql_engine.cnf`
```sh
[client]
user=user1
password=password1
host=mysql_host1
database=database1
[devops]
user=user2
password=password2
host=mysql_host2
database=database2
```
- ENVIRONMENT - string parameter
- DB_HOST - string parameter
- DATABASE - string parameter

### Execution
```
./check_client.py "$ENVIRONMENT" "$DB_HOST" "$DATABASE"
```
### Description:
1. Collect information about game.
2. Create game_client_data.csv file
3. Get game client version from s3
