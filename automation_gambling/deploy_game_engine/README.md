# Game management (**#Python3**)
---
### Description
# Preparation on Windows host
0. Check wrapper service [winsw page](https://github.com/winsw/winsw)
1. Copy last stable release (7.9.0.0p1-beta):
https://github.com/PowerShell/Win32-OpenSSH/releases
2. Unpack files into C:\Program Files\OpenSSH
Note: write permissions should be only in SYSTEM and admin groups.
3. Install Win32-OpenSSH services:
```sh
 > powershell.exe -ExecutionPolicy Bypass -File install-sshd.ps1
```
4. Open port 22 for ssh connection:
```sh
 > New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
```
**Note**: applet New-NetFirewallRule is used on Windows Server 2012 ++. In old releases we can use:
```sh
 > netsh advfirewall firewall add rule name=sshd dir=in action=allow protocol=TCP localport=22
```
5. Start sshd service:
```sh
 > net start sshd
```
6. Add sshd service in system startup script
```sh
 > Set-Service sshd -StartupType Automatic
```
7. Setup **sshd_config** in **C:\ProgramData\ssh** directory:
```sh
    PasswordAuthentication no
    PubkeyAuthentication yes
    StrictModes no
```
8. Create **administrators_authorized_keys** file in **C:\ProgramData\ssh** directory and add **Jenkins public key** there.
9. Restart sshd service after all changes
```sh
 > net stop sshd
 > net start sshd
```
10. Install dotnet-sdk  v3.1.10 on WINDOWS host  - https://dotnet.microsoft.com/download/dotnet/3.1
---
# Preparation on Jenkins host
1. Edit **ssh config** file:
```sh
> ~/.ssh/config
    Host 10.*
    StrictHostKeyChecking no
    UserKnownHostsFile=/dev/null
```
2. Create file with database credentials:
```sh
> /var/lib/jenkins/engine.cnf
    [client]
    user=
    password=
    [devops]
    user=
    password=
    host=
    database=
```
3. Create Jenkins job with **groovy** format parameter
```sh
import groovy.sql.Sql
def output = []
def sql = Sql.newInstance('jdbc:mysql://HOST:PORT/DATABASE', 'user', 'password', 'com.mysql.jdbc.Driver')
def sqlString='select game_name from game where order by game_name;'
sql.eachRow(sqlString){
    output.push(it[0])
}
sql.close()
return output
```
**jdbc.Driver** should be installed on Jenkins server:
```sh
 > wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.49.zip
 > sudo cp mysql-connector-java-5.1.49.jar /usr/lib/jvm/java/jre/lib/ext/
 > ll /usr/lib/jvm/java/jre/lib/ext/
    -rw-r--r--. 1 root root 1006904 Jun 11 09:13    mysql-connector-java-5.1.49.jar
 > sudo service jenkins restart
```
3. Perform next **ACTIONS** for game management:
 - **START**
 - **STOP**
 - **RESTART**
---
# Changes in proxy configuration
```sh
    upstream <gamename> {
        server app01-<ENV>:<PORT>;
    }
    
    location /<gamename> {
        proxy_pass http://<gamename>/;
    }
```
