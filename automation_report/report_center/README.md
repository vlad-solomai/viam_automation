# Create report
### Skills summary:
- **#python3**
- **#mysql**
- **#aws**

### Requirements
- AWS credentials in `~/.aws/credentials`
- MySQL credentials in `~/.my.cnf`
- Date format **yyyy-MM-dd**
- ENVIRONMENT - Hidden Parameter
- MYSQL_REPLICA - Hidden Parameter
- MYSQL_DB - Hidden Parameter
- TIME_ZONE_START - Hidden Parameter
- TIME_ZONE_END - Hidden Parameter
- OPERATOR_NAME - Active Choices Parameter shows operators with param_key="reportList"
```
import groovy.sql.Sql

def output = []

def sql=Sql.newInstance("jdbc:mysql://<MYSQL_REPLICA>:3306/<MYSQL_DB>", "<USERNAME>", "<PASSWORD>", "com.mysql.jdbc.Driver")
def sqlString='SELECT core_operator.operator_name \
FROM core_operator INNER JOIN core_operator_params \
ON core_operator.operator_id = core_operator_params.operator_id WHERE core_operator_params.param_key="reportList";'
sql.eachRow(sqlString) {
    output.push(it[0])
}  
sql.close()
return output
```
- OPERATOR_ID - Active Choices Reactive Parameter, referenced with OPERATOR_NAME
```
import groovy.sql.Sql

def output = []

def sql=Sql.newInstance("jdbc:mysql://<MYSQL_REPLICA>:3306/<MYSQL_DB>", "<USERNAME>", "<PASSWORD>", "com.mysql.jdbc.Driver")
def sqlString="select operator_id from core_operator where operator_name='$OPERATOR_NAME' order by operator_name;"
sql.eachRow(sqlString) {
    output.push(it[0])
}  
sql.close()
return output
```
- START_DATE - Data Picker parameter (yyyy-MM-dd format)
- END_DATE - Data Picker parameter (yyyy-MM-dd format)
- AGGREGATE_REPORT_VALUE - Hidden Parameter Collect aggregated report (Yes/No)


### Project structure:
```
report_management/
├── http_credentials/             # directory with certificate to http server
│   ├── cert_1                    # cert_{operator_id} format
│   └── key_1                     # key_{operator_id} format
├── report_manager.py             # main script
├── sftp_credentials/             # directory with passwords to sftp server
│   ├── sftp_1                    # sftp_{operator_id} format
│   ├── sftp_dge                  # password to DGE sftp
│   └── sftp_gnac                 # password to GNAC sftp
└── sql_requests/                 # directory with report methods
    ├── date_convertor.py         # return environment time zone difference
    ├── GameSummary.py            # return SQL request for dgeGameSummaryReport report
    ├── pendingReports.py         # return SQL request for dgePendingReport report
    ├── voidReports.py            # return SQL request for dgeVoidReport report
    ├── __init__.py               # connect methods with report_manager.py script 
    └── operator_data.py          # return SQL request with operator information
```

### Description:
Script flow based on work with information about operator params in the next dictionary format (example below):
- ‘reportEndpointSftpDge’: ‘user@sftp.com:/test_reports/DGE/',
- 'reportEndpointSftpGnac’: ‘user@sftp.com:/test_reports/GNAC/',
- 'reportEndpointSftpOperator’: ‘user@sftp.com:/test_reports/OPERATOR/',
- 'reportEndpointHttpOperator’: ‘https://server
- 'reportEndpointEmailOperator’: ‘<email>'
- ’reportAggregatedName': ‘<name of aggregated report>'
- ’reportAggregatedOperators': '<list of operators for aggregated report>'
S3 storage with reports: reports/<report_name>/<environment>/<operator_name>/<yyyy-MM>/<report_name>.csv

Operators with Aggregated reports should be at the end of the list:

For failed delivery notification will be sent to the #monitoring slack channel.
```
Report processing on PP:
               ERROR: Can`t send report pendingReports_122021.csv to '---', check connection or credentials
Report processing on PP:
               ERROR: Can`t send report voidReports_122021.csv to '888_nj@sftp.com:/test_reports/DGE/', check connection or credentials
Report processing on PP:
               ERROR: Can`t send report voidReports_122021.csv to '888_nj@sftp.com:/test_reports/GNAC/', check connection or credentials
Report processing on PP:
               ERROR: Can`t send report voidReports_122021.csv to '---', check connection or credentials
```

### Jenkins job:
```
if [[ -z $START_DATE ]] && [[ -z $END_DATE ]] && [[ -z $OPERATOR_ID ]]; then
    OPERATOR_ID="100 43 67 77 76 75 71 127 56 193 171 66 78"

    for OP_ID in ${OPERATOR_ID[@]}; do
        START_DATE=$(date '+%Y-%m-%d' -d '1 day ago')
        END_DATE=$(date '+%Y-%m-%d')
        echo "RUN SCRIPT FROM ${START_DATE} to ${END_DATE}"
        $JENKINS_HOME/devops-prod/scripts/report_management/report_manager.py "$OP_ID" "$START_DATE" "$END_DATE" "$TIME_ZONE_START" "$TIME_ZONE_END" "$ENVIRONMENT" "$MYSQL_REPLICA" "$MYSQL_DB" "$AGGREGATE_REPORT_VALUE"
        sleep 60
    done
else
    while [[ ${START_DATE} != ${END_DATE} ]]; do
        NEXT_DAY=$(date +%Y-%m-%d -d "$START_DATE +1 day")
        echo "RUN SCRIPT FROM ${START_DATE} to ${NEXT_DAY}"
        $JENKINS_HOME/devops-prod/scripts/report_management/report_manager.py "$OPERATOR_ID" "$START_DATE" "$NEXT_DAY" "$TIME_ZONE_START" "$TIME_ZONE_END" "$ENVIRONMENT" "$MYSQL_REPLICA" "$MYSQL_DB" "$AGGREGATE_REPORT_VALUE"
        START_DATE=$(date +%Y-%m-%d -d "$START_DATE +1 day")
    done
fi
```
