#!/bin/python3
from sys import argv
from datetime import datetime
import mysql.connector
import csv
import pysftp
import subprocess
import requests
from requests.exceptions import HTTPError
import os
import boto3
from botocore.exceptions import ClientError
from slack import WebClient
from slack.errors import SlackApiError
from sql_requests import *


slack_channel = "#monitoring"
operator_id = argv[1]
start_date = argv[2]
environment = argv[6]
database_conf = "/var/lib/jenkins/engine.cnf"
report_host = argv[7]
report_db = argv[8]
aggregate_report_value = argv[9]
operator_data_dict = {}
report_manager_dir = os.path.abspath(os.path.dirname(__file__))


def connect_to_mysqldb(action: str, config_option: str, database_host: str, database: str, custom_query: str):
    '''
    The function works with the SQL requsts from "sql_requests" folder:
     - "select" means only SELECT statement
     - "execute" means UPDATE, DROP, CREATE, DELETE (except SET)
    and return results of SQL operations and table column headings separatelly.
    '''
    try:
        db_connection = mysql.connector.connect(option_files=database_conf,
                                                option_groups=config_option,
                                                host=database_host,
                                                database=database)
        cursor = db_connection.cursor()
        cursor.execute(custom_query)
        print(f"\n{custom_query}")
        if action == "select":
            results = cursor.fetchall()
            return results, cursor.description
            cursor.execute("SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;")
        elif action == "execute":
            db_connection.commit()
            print("*** During update record(s) affected: ", cursor.rowcount)
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
    finally:
        if (db_connection.is_connected()):
            db_connection.close()
            cursor.close()


def get_operator_data():
    '''The function collects information about operators from sql_requests/operator_data.py file'''
    global operator_name, report_name

    operator_result = connect_to_mysqldb("select", "client", report_host, report_db, operator_data.operator_name)[0]
    for op_name in operator_result:
        operator_name = op_name[0].replace(" ", "_")

    report_result = connect_to_mysqldb("select", "client", report_host, report_db, operator_data.operator_reports)[0]
    for r_name in report_result:
        report_name = r_name[0].replace(" ", "")

    param_result = connect_to_mysqldb("select", "client", report_host, report_db, operator_data.core_parameters)[0]
    for data in param_result:
        param_key = data[0]
        param_value = data[1]
        operator_data_dict[param_key] = param_value


def notify_slack(filename, endpoint):
    '''The function sends notification about failed delivery via slack'''
    slack_token = "xoxp-229522615970"
    client = WebClient(token=slack_token)
    user="jenkins-bot"
    try:
        response = client.chat_postMessage(
            channel = slack_channel,
            text = """*Report processing on {2}:*
                *ERROR:* Can`t send report {0} to '{1}', check connection or credentials
            """.format(filename, endpoint, environment)
        )
    except SlackApiError as e:
        assert e.response["error"]


def send_email(filename: str, report_endpoint: str, recipient_list: List[str]):
    '''The function sends report via email'''
    if report_endpoint.startswith("reportEndpointEmailOperator"):
        for email in recipient_list.replace(" ", "").split(","):
            print(f"SENDING REPORT {filename} TO MAILBOX {email}")
            try:
                cmd="""echo "AGS - {0} Report for {3}" | mailx -v -A support -s "AGS - {0} Report for {3}" -a {1} {2}""".format(operator_name, filename, email, start_date)
                p=subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT) #PIPE to print output
                output, errors = p.communicate()
            except:
                print(f"*** ERROR: Can`t send report {filename} to {email}, check connection or credentials")
                notify_slack(filename, email)


def send_to_sftp(filename: str, report_endpoint: str, sftp_endpoint: str):
    '''The function sends report via sftp using credentials from sftp_credentials'''
    sftp_cred_dir = f"{report_manager_dir}/sftp_credentials/{environment}"
    if report_endpoint.startswith("reportEndpointSftp"):
        for sftp in sftp_endpoint.replace(" ", "").split(","):
            if report_endpoint == "reportEndpointSftpDge":
                sftp_passwd_path = f"{sftp_cred_dir}/sftp_dge"
            elif report_endpoint == "reportEndpointSftpGnac":
                sftp_passwd_path = f"{sftp_cred_dir}/sftp_gnac"
            else:
                sftp_passwd_path = f"{sftp_cred_dir}/sftp_{operator_id}"
            with open(sftp_passwd_path, 'r') as f:
                sftp_passwd = f.read().rstrip()
            sftp_user = sftp.split(":")[0].split("@")[0]
            sftp_server = sftp.split(":")[0].split("@")[1]
            sftp_folder = sftp.split(":")[1]
            print(f"SENDING REPORT {filename} TO SFTP {sftp_server}:{sftp_folder}")
            try:
                with pysftp.Connection(sftp_server, username=sftp_user, password=sftp_passwd) as sftp:
                    with sftp.cd(sftp_folder):
                        sftp.put(filename)
            except:
                print(f"*** ERROR: Can`t send report {filename} to SFTP {sftp_server}:{sftp_folder}, check connection or credentials")
                notify_slack(filename, sftp)


def send_to_http(filename: str, report_endpoint: str, http_endpoint: str):
    '''The function sends report via http using credentials from http_credentials'''
    try:
        http_cred_dir = f"{report_manager_dir}/http_credentials/{environment}"
        if report_endpoint == "reportEndpointHttpOperator":
            with open(filename, "rb") as r_file:
                file_dict = {filename: r_file}
                response_post = requests.post(http_endpoint, files=file_dict, cert=(f"{http_cred_dir}/cert_{operator_id}", f"{http_cred_dir}/key_{operator_id}"))
                print(f"SENDING REPORT {filename} TO HTTP {http_endpoint}: status {response_post.status_code}")
    except HTTPError as http_err:
        print("*** ERROR: HTTP error occurred: {}".format(http_err))
        notify_slack(filename, http_endpoint)
    except Exception as err:
        print("*** ERROR: Other error occurred: {}".format(err))
        notify_slack(filename, http_endpoint)


def send_to_s3(o_name: str, report_type: str, filename: str, month: str) -> bool:
    '''The function sends report to AWS S3 using jenkins credentials'''
    bucket_name = "reports"
    folder_path = f"{report_type}/{environment}/{o_name}/{month}/{filename}"
    print(f"SENDING REPORT {filename} TO S3 {folder_path}")
    s3 = boto3.resource('s3')
    try:
        s3.meta.client.upload_file(
            Filename=filename,
            Bucket=bucket_name,
            Key=folder_path
        )
        return True
    except ClientError as err:
        print("*** Error during uploading to s3: {}".format(err))
        return False


def download_from_s3(o_name: str, report_type: str, filename: str, month: str) -> str:
    '''The function download report from AWS S3 using jenkins credentials'''
    bucket_name = "reports"
    folder_path = f"{report_type}/{environment}/{o_name}/{month}/{filename}"
    print(f"DOWNLOADING REPORT {filename} from S3 {folder_path}")
    s3 = boto3.resource('s3')
    try:
        s3.Bucket(bucket_name).download_file(folder_path, filename)
        return "Success"
    except ClientError as err:
        return "Failure"


def create_csv_file(report_header: str, report_data: str, filename: str):
    '''The function creates file in a csv format according to the input information'''
    with open(filename, 'w') as data_file:
        data_write = csv.writer(data_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        data_write.writerow([i[0] for i in report_header]) # write headers
        for row in report_data:
            data_write.writerow(row)


def read_csv_file(filename: str):
    '''The function displays report information'''
    print (f"\nREPORT COLLECTED: {filename}")
    with open(filename, "r") as log_file:
        for line in log_file:
            print(line.rstrip())
    print ("\n")


def create_report(report_type: str, report_csv_file: str):
    '''The function creates different types of reports'''
    if report_type == "pendingReports":
        if not os.path.exists(report_csv_file):
            print(f"===== Creating {report_type} for {operator_name}")
            report_sql_result = connect_to_mysqldb("select", "client", report_host, report_db, pendingReports.report)[0]
            report_sql_header = connect_to_mysqldb("select", "client", report_host, report_db, pendingReports.report)[1]
            create_csv_file(report_sql_header, report_sql_result, report_csv_file)
    elif report_type == "voidReports":
        if not os.path.exists(report_csv_file):
            print(f"===== Creating {report_type} for {operator_name}")
            report_sql_result = connect_to_mysqldb("select", "client", report_host, report_db, voidReports.report)[0]
            report_sql_header = connect_to_mysqldb("select", "client", report_host, report_db, voidReports.report)[1]
            create_csv_file(report_sql_header, report_sql_result, report_csv_file)
    elif report_type == "GameSummary":
        if not os.path.exists(report_csv_file):
            print(f"===== Creating {report_type} for {operator_name}")
            connect_to_mysqldb("execute", "client", report_host, report_db, GameSummary.drop_tmp_game_cycle_table)
            connect_to_mysqldb("execute", "client", report_host, report_db, GameSummary.create_tmp_game_cycle_table)
            connect_to_mysqldb("execute", "client", report_host, report_db, GameSummary.insert_tmp_game_cycle_table)
            connect_to_mysqldb("execute", "client", report_host, report_db, GameSummary.drop_tmp_transaction_table)
            connect_to_mysqldb("execute", "client", report_host, report_db, GameSummary.create_tmp_transaction_table)
            connect_to_mysqldb("execute", "client", report_host, report_db, GameSummary.insert_tmp_transaction_table)
            report_sql_result = connect_to_mysqldb("select", "client", report_host, report_db, GameSummary.report)[0]
            report_sql_header = connect_to_mysqldb("select", "client", report_host, report_db, GameSummary.report)[1]
            create_csv_file(report_sql_header, report_sql_result, report_csv_file)


def search_string(filename: str, text_string: str) -> str:
    '''
    The function checks row with operator name delimiter in aggregation report,
    which means that data for aggregation report was already collected.
    '''
    with open(filename) as f:
        if text_string in f.read():
            return "Found"


def merge_csv_files(filename1: str, filename2: str, delimiter: str):
    '''The function writes operator`s report into aggregation report'''
    with open(filename1, 'a') as a_file:
        with open(filename2) as r_file:
           a_file.write(r_file.read())
        a_file.write(f"{delimiter}\n\n")


def aggregate_report(aggr_param_name: str, report_type: str, report_date: str, report_month: str) -> str:
    '''The function creates aggregation report for list of the operator names'''
    aggregated_param = connect_to_mysqldb("select", "client", report_host, report_db, operator_data.aggregated_operators)[0]
    if aggregated_param != "" or aggregated_param is not None:
        for ag_op in aggregated_param:
            aggregated_operators = ag_op[0]
            for op_name in aggregated_operators.split(","):
                client_name = op_name.strip().replace(" ", "_")
                operator_csv_file = "{0}_{1}_{2}.csv".format(client_name, report_type, report_date)
                if not os.path.exists(operator_csv_file):
                    downloaded_s3_report = download_from_s3(client_name, report_type, operator_csv_file, report_month)
                    if downloaded_s3_report == "Success":
                        print(f"The {operator_csv_file} successfully dowloaded from S3")
                print(f"===== Adding {client_name}`s {report_type} report into aggregated {aggr_param_name}")
                aggr_csv_file = f"{aggr_param_name}_{report_type}_{report_date}.csv"
                aggr_delimiter = f"{client_name} --------"
                downloaded_aggr_report = download_from_s3(operator_name, "AggregatedReport", aggr_csv_file, report_month)
                if downloaded_aggr_report == "Success":
                    print(f"The {aggr_csv_file} successfully dowloaded from S3")
                    search_result = search_string(aggr_csv_file, aggr_delimiter)
                    if search_result == "Found":
                        print(f"Information is already in the {aggr_csv_file} report")
                    else:
                        merge_csv_files(aggr_csv_file, operator_csv_file, aggr_delimiter)
                elif downloaded_aggr_report == "Failure":
                    print(f"*** The {aggr_csv_file} does not exist on S3, will create it locally")
                    os.system(f"cp -p {operator_csv_file} {aggr_csv_file}")
                    with open(aggr_csv_file, 'a') as data_file:
                        data_file.write(f"{aggr_delimiter}\n\n")
                send_to_s3(operator_name, "AggregatedReport", aggr_csv_file, report_month)
            return aggr_csv_file


def report_processing():
    '''The function works with reports flows'''
    for r_name in report_name.split(","):
        date_format = datetime.strptime(start_date, '%Y-%m-%d')
        date_string =  datetime.strftime(date_format, '%m%d%y')
        date_month = datetime.strftime(date_format, '%Y-%m')
        csv_file = "{0}_{1}_{2}.csv".format(operator_name, r_name, date_string)
        create_report(r_name, csv_file)
        read_csv_file(csv_file)
        send_to_s3(operator_name, r_name, csv_file, date_month)
        for key, val in operator_data_dict.items():
            if val != "" or val is not None:
                if os.path.exists(csv_file):
                    send_email(csv_file, key, val)
                    send_to_http(csv_file, key, val)
                    send_to_sftp(csv_file, key, val)
        if aggregate_report_value == "Yes":
            aggregated_result = connect_to_mysqldb("select", "client", report_host, report_db, operator_data.aggregated_name)[0]
            if aggregated_result != "" or aggregated_result is not None:
                for ag_name in aggregated_result:
                    aggregated_name = ag_name[0]
                    aggregated_csv_file = aggregate_report(aggregated_name, r_name, date_string, date_month)
                    for key, val in operator_data_dict.items():
                        if val != "" or val is not None:
                            if os.path.exists(aggregated_csv_file):
                                send_email(aggregated_csv_file, key, val)
                                send_to_http(aggregated_csv_file, key, val)
                                send_to_sftp(aggregated_csv_file, key, val)


def main():
    get_operator_data()
    print(operator_data_dict)
    print(report_name)
    report_processing()


if __name__ == '__main__':
    main()
