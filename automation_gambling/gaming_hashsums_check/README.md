# Gaming hashsums check
### Skills summary:
- **#python3**
- **#mysql**
- **#aws**
- **#slack**

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
- REMOTE_HOST - string parameter, list of hosts (host1,host2)
- REMOTE_USER - string parameter, windows user
- DATABASE_HOST - string parameter
- DATABASE - string parameter
### Preparation
```
sudo yum install gcc
sudo yum install python3-devel
sudo pip3 install slack
sudo pip3 install slackclient
```
### Execution
```
./gaming_hashsums_check.py "$ENVIRONMENT" "$REMOTE_HOST" "$REMOTE_USER" "$DATABASE_HOST" "$DATABASE"
```
### Description:
Script `gaming_hashsums_check.py` check hashsumm of game applications:
1. Clone repo with proxy configuration.
2. Collect game application hashsumm on host.
3. Сompare collected hashsumm with information from database.
4. Notify slack about the differences if needed.

#### Example of successful game check:
```
game_name_7098
{'Commons.dll,10.1.1.1': 'ad4fd54ac3985036b7ec14d51,2021-07-26 10:48:37', 'Game.dll,10.1.1.1': '84a64f904838d72637,2021-07-26 10:48:37', 'SocketServer.exe,10.1.1.1': '9e6dae8ad262158,2021-07-26 10:48:37', 'Slots.dll,1.1.1.1': '2a3ef4b9d92,2021-07-26 10:48:37', 'Math.json,1.1.1.1': 'acdd03e99c44dbfdba,2021-07-26 10:48:37'}
*** During update record(s) affected:  1
*** During update record(s) affected:  1
*** During update record(s) affected:  1
*** During update record(s) affected:  1
*** During update record(s) affected:  1
```
#### Example of failed game check:
```
game_name_9121
{'Commons.dll,1.1.1.1': '367ab4e37ab6ba395b5e,2021-07-26 10:16:46', 'Game.dll,1.1.1.1': 'cda36b5a31668470,2021-07-26 10:16:46', 'SocketServer.exe,1.1.1.1': 'cb140dfca8c847b0c88,2021-07-26 10:16:46', 'Slots.dll,1.1.1.1': 'e4aa9964f4248ce4a,2021-07-26 10:16:46', 'Math.json,1.1.1.1': '7e49c1e554ad3130,2021-07-26 10:16:46'}
*** During update record(s) affected:  1
Hash sum has been changed, check slack
*** During update record(s) affected:  1
Hash sum has been changed, check slack
*** During update record(s) affected:  1
Hash sum has been changed, check slack
*** During update record(s) affected:  1
Hash sum has been changed, check slack
*** During update record(s) affected:  1
Hash sum has been changed, check slack
```
#### Slack notification:
```
Hash sum has been changed:
               ENVIRONMENT: STAGE
               HOST: 1.1.1.1
               APPLICATION: game_name_9121
               FILE: Math.json
               DEVOPS HASH_SUM: 7e49c1e49bc15ed121549610
               REMOTE HASH_SUM: CertUtil:Thesystemcannotfindthepathspecified.
```
