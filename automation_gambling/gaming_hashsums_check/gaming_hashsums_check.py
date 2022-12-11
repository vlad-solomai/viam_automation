#!/bin/python3

import sys
import os
import mysql.connector
from sys import argv
import hashlib
import datetime
import subprocess
from slack import WebClient
from slack.errors import SlackApiError


environment = argv[1]
remote_host = argv[2].split(",")
remote_user = argv[3]
env_mysql_host = argv[4]
env_mysql_db = argv[5]
devops_host = "devops.host.com"
devops_db = "devops"
remote_path = 'C:\\Games'
database_conf = "/var/lib/jenkins/mysql_engine.cnf"
slack_channel = "#test"
code_url = "git clone ssh://git-codecommit.eu-west-1.amazonaws.com/v1/repos/"
proxy_config = "openresty-config/"
engine_data_dict = {}
artifact_data_dict = {}
application_data_dict = {
  "proxy01,platform": "/opt/game/platform/platform.jar",
  "proxy01,backoffice": "/opt/game/backoffice/backoffice.jar",
  "proxy01,RGS": "/home/glassfish/glassfish4/glassfish/domains/game/applications/__internal/RGS/RGS.ear",
  "proxy01,wrapper": "/opt/game/wrapper/wrapper.jar",
  "proxy02,gameconfig": "/opt/game/gameconfig/gameconfig.jar",
  "proxy02,rng": "/opt/game/rng/rng.jar"
}
sql_game_engine = """select game_name, short_code, mgs_code from core_game
                     where provider_id=48 and mgs_code IS NOT NULL order by game_name;"""


def clone_repo(repo_name: str):
    try:
        if os.path.exists(repo_name):
            os.chdir(repo_name)
            os.system("git pull")
            print("*** Repository {} was successfully updated".format(repo_name))
        else:
            clone = code_url + repo_name
            os.system(clone)
            os.chdir(repo_name)
            print("*** Repository {} was successfully downloaded".format(repo_name))
    except OSError as e:
        print("*** ERROR: {}".format(sys.exc_info()[1]))
        exit()


def connect_with_mysqldb(action: str, config_option: str, database_host: str, database: str, custom_query: str):
    try:
        db_connection = mysql.connector.connect(option_files=database_conf,
                                                option_groups=config_option,
                                                host=database_host,
                                                database=database)
        cursor = db_connection.cursor()
        query = custom_query
        cursor.execute(query)
        if action == "select":
            results = cursor.fetchall()
            return results
        elif action == "update":
            db_connection.commit()
            print("*** During update record(s) affected: ", cursor.rowcount)
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
    finally:
        if (db_connection.is_connected()):
            db_connection.close()
            cursor.close()


def get_game_engine_data():
    engine_data = connect_with_mysqldb("select", "client", env_mysql_host, env_mysql_db, sql_game_engine)
    for data in engine_data:
        game_name = data[0]
        game_code = data[1]
        game_port = str(data[2]).split(" ")
        for port in game_port:
            if port != "":
                engine_data_dict["{0}_{1}".format(game_code, port)] = game_name


def get_deployment_game_data():
    artifact_data = connect_with_mysqldb("select", "devops", devops_host, devops_db, sql_game_artifact)
    for data in artifact_data:
        game_artifact = data[0]
        sha1sum = data[1]
        deployment_date = data[2]
        deployment_host = data[3]
        artifact_cred = "{0},{1}".format(game_artifact, deployment_host)
        sha1sum_cred = "{0},{1}".format(sha1sum, deployment_date)
        artifact_data_dict[artifact_cred] = sha1sum_cred


def get_deployment_app_data():
    artifact_data = connect_with_mysqldb("select", "devops", devops_host, devops_db, sql_app_artifact)
    for data in artifact_data:
        sha1sum = str(data[0])
        deployment_date = data[1]
        deployment_host = data[2]
        sha1sum_cred = "{0},{1}".format(sha1sum, deployment_host)
        artifact_data_dict[sha1sum_cred] = deployment_date


def notify_slack(remote_host: str, remote_app: str, critical_file: str, db_sha1summ: str, host_sha1summ: str):
    slack_token = "xoxp-229522615970"
    client = WebClient(token=slack_token)
    user="jenkins-bot"
    try:
        response = client.chat_postMessage(
            channel = slack_channel,
            text = """*Hash sum has been changed:*
                *ENVIRONMENT:* {0}
                *HOST:* {1}
                *APPLICATION:* {2}
                *FILE:* {3}
                *DEPLOYED HASH_SUM:* {4}
                *REMOTE HASH_SUM:* {5}
            """.format(environment, remote_host, remote_app, critical_file, db_sha1summ, host_sha1summ)
        )
    except SlackApiError as e:
        assert e.response["error"]


def get_engine_data(game_name: str, game_path: str):
    for artifact, sha1sum in artifact_data_dict.items():
        depl_host = artifact.split(",")[1]
        depl_artifact = artifact.split(",")[0]
        depl_sha1summ = str(sha1sum.split(",")[0]).upper()
        depl_date = sha1sum.split(",")[1]
        ssh_cmd = '"CertUtil -hashfile {0}\\{1}\\{2}"'.format(remote_path, game_path, depl_artifact)
        ssh_options = '-q -o "StrictHostKeyChecking no"'
        ssh_check = subprocess.run(["ssh {3} {0}@{1} {2}".format(remote_user, ip, ssh_cmd, ssh_options)],
                                       shell=True, stdout=subprocess.PIPE, encoding='utf-8')
        ssh_result = (ssh_check.stdout).split('\n')[1].replace(" ","").upper()
        if depl_sha1summ == "None":
            sql_update_game = """UPDATE deployments SET Last_check='{0}'
                WHERE Product='{1}' and Environment='{5}' and Artifact='{2}' and MD5sum IS NULL and host='{3}' and Date='{4}';
                """.format(last_check, game_name, depl_artifact, depl_host, depl_date, environment)
        else:
            sql_update_game = """UPDATE deployments SET Last_check='{0}'
                WHERE Product='{1}' and Environment='{6}' and Artifact='{2}' and MD5sum='{3}' and host='{4}' and Date='{5}';
                """.format(last_check, game_name, depl_artifact, depl_sha1summ, depl_host, depl_date, environment)
        connect_with_mysqldb("update", "devops", devops_host, devops_db, sql_update_game)
        if ((depl_sha1summ == "" or depl_sha1summ == "None") and ssh_result != "CertUtil:Thesystemcannotfindthepathspecified.") or \
           ((depl_sha1summ != "" or depl_sha1summ != "None") and ssh_result != depl_sha1summ):
            print("Hash sum has been changed, check slack")
            notify_slack(ip, game_path, depl_artifact, depl_sha1summ, ssh_result)
    artifact_data_dict.clear()


def get_application_data():
    for app_sha1summ, depl_date in artifact_data_dict.items():
        depl_sha1summ = app_sha1summ.split(",")[0].upper()
        depl_host = app_sha1summ.split(",")[1]
        ssh_cmd = '"sudo sha1sum {}"'.format(app_artifact)
        ssh_options = '-q -o "StrictHostKeyChecking no"'
        ssh_check = subprocess.run(["ssh {2} {0} {1}".format(app_host, ssh_cmd, ssh_options)],
                                   shell=True, stdout=subprocess.PIPE, encoding='utf-8')
        ssh_result = ssh_check.stdout.strip().split()[0].upper()
        print(application, app_host, depl_sha1summ, ssh_result)
        if depl_sha1summ == "None":
            sql_update_app = """UPDATE deployments SET Last_check='{0}'
                WHERE Product='{1}' and Environment='{4}' and MD5sum IS NULL and Date='{2}' and host='{3}';
                """.format(last_check, application, depl_date, depl_host, environment)
        else:
            sql_update_app = """UPDATE deployments SET Last_check='{0}'
                WHERE Product='{1}' and Environment='{5}' and MD5sum='{2}' and Date='{3}' and host='{4}';
                """.format(last_check, application, depl_sha1summ, depl_date, depl_host, environment)
        connect_with_mysqldb("update", "devops", devops_host, devops_db, sql_update_app)
        empty_result = "sha1sum: {}: No such file or directory".format(app_artifact)
        if ((depl_sha1summ == "" or depl_sha1summ == "None") and ssh_result != empty_result) or \
           ((depl_sha1summ != "" or depl_sha1summ != "None") and ssh_result != depl_sha1summ):
            print("Hash sum has been changed, check slack")
            print(application, depl_sha1summ, ssh_result, depl_host)
            notify_slack(app_host, application, app_artifact, depl_sha1summ, ssh_result)
    artifact_data_dict.clear()


def main():
    clone_repo(proxy_config)
    last_check = datetime.datetime.now()
    get_game_engine_data()
    print(engine_data_dict)
    for ip in remote_host:
        for g_code, g_name in engine_data_dict.items():
            sql_game_artifact = """select Artifact, MD5sum, Date, Host from deployments
                where Date=(select max(Date) from deployments where Product='{0}' and Environment='{1}' and Host='{2}')
                and Environment='{1}' and Product='{0}' and Host='{2}';""".format(g_name, environment, ip)
            get_deployment_game_data()
            print(g_code)
            print(artifact_data_dict)
            get_engine_data(g_name, g_code)

    for app, app_artifact in application_data_dict.items():
        proxy = app.split(",")[0]
        application = app.split(",")[1]
        if application == "RGS":
            config_file = "{0}/{1}-{2}/conf/conf.d/wallet.conf".format(environment, proxy, environment.lower(), application)
        elif application == "gameconfig" or application == "rng":
            config_file = "{0}/{1}-{2}/conf/conf.d/{3}-{2}.conf".format(environment, proxy, environment.lower(), application)
        else:
            config_file = "{0}/{1}-{2}/conf/conf.d/{3}.conf".format(environment, proxy, environment.lower(), application)
        with open(config_file, "r") as hostfile:
            for line in hostfile:
                if " server " in line:
                    app_host = (line.strip().split(":")[0]).split(" ")[-1]
                    sql_app_artifact = """select MD5sum, Date, Host from deployments
                        where Date=(select max(Date) from deployments where Product='{0}' and Environment='{1}' and Host='{2}')
                        and Environment='{1}' and Product='{0}' and Host='{2}';""".format(application, environment, app_host)
                    get_deployment_app_data()
                    get_application_data()


if __name__ == '__main__':
    main()
