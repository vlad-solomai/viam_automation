# Deploy Game Client
### Skills summary:
- **#python3**
- **#mysql**
- **#aws**

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

- GAME_NAME - active choise reactive parameter
```
import groovy.sql.Sql 
def output = []
def sql = Sql.newInstance('jdbc:mysql://mysql_host:3306/mysql_db', 'mysql_user', 'mysql_password', 'com.mysql.jdbc.Driver')
def sqlString = 'select game_name from core_game where provider_id=48 order by game_name;'
sql.eachRow(sqlString) {
    social = it[0].contains(" Social")
    colombia = it[0].contains(" Colombia")
    if (!colombia) {
        output.push(it[0])
    }
}
sql.close()
return output
```
- S3_DIRECTORY - string parameter
- BACKOFFICE_URL - string parameter
- ENABLE_FORSING - active choise reactive parameter
```
if (INFRASTRUCTURE.equals("STAGE")) {
    return ["true", ""]
} else {
    return [""]
}
``` 
- CLIENT_VERSION - active choise reactive parameter
```
import groovy.sql.Sql 

def short_code = []
def sql = Sql.newInstance('jdbc:mysql://mysql_host:3306/mysql_db', 'mysql_user', 'mysql_password', 'com.mysql.jdbc.Driver')
def sqlString = "select short_code from core_game where game_name='$GAME_NAME'".replaceAll("Social", "")
sql.eachRow(sqlString) {
    short_code.push(it[0].replaceAll("_", ""))
}
sql.close()

def version_output = []

short_code.each {
    def s3SubDir = ["qa", "test"]
    for (env in s3SubDir) {
        def command = ("aws s3 ls s3://cdn.project.com/ags/${env}/${it}/").execute().text.trim()
        command.eachLine { line ->
            if (line.split()[0]=="PRE") {
                def version = line.split()[1].replaceAll("/","")
                def s3_path = "${env}/${version}"
                version_output.push(s3_path.toString())
            }
        }
    }
}
return version_output.sort()
```
- ENVIRONMENT - string parameter
- BUILD_NUMBER - jenkins user build variables
- PERFORMER - jenkins user build variables


### Execution
```
./deploy_game_client.py "$GAME_NAME" "$S3_DIRECTORY" "$BACKOFFICE_URL" "$ENABLE_FORSING" "$CLIENT_VERSION" "$ENVIRONMENT" "$BUILD_NUMBER" "$PERFORMER"
```
### Description:
1. Collect information about game.
2. Download required client from S3
3. Update database with hashsumm of control files
4. Modify game client json file with enable forcing
5. Upload game client to S3 diroctory
6. Modify bachoffice urls
7. Invalidate s3 cache

#### Example of successful game check:
```
*** Collecting information about Game
*** Data was successfully collected
*** MySQL connection is closed
*** Uploading Game version:1.1.3 to S3
    START TIME: Thu Oct  7 10:34:52 2021
    - Files to upload: 516
    - Total size to upload: 193MB
    FINISH TIME: Thu Oct  7 10:35:32 2021
*** Changing Launch Adresses
    - DesktopLaunchAddress: https://cdn.project.com
    - MobileLaunchAddress: https://cdn.project.com
*** Clean Cache: status 200
*** Data dir/game/version/* was invalidated on s3.
*** game was successfully removed from workspace
```
