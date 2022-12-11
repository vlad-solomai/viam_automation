#!/bin/python3

import subprocess
import csv
import mysql.connector
from sys import argv

environment = argv[1]
env_mysql_host = argv[2]
env_mysql_db = argv[3]
database_conf = "/var/lib/jenkins/mysql_engine.cnf"
s3_bucket = "cdn.project.com"
game_data_dict = {}
version_list = set()
sql_game_engine = """select short_code, desktop_launch_address from core_game
                     where provider_id=48 and mgs_code IS NOT NULL and short_code!='adaptor' order by game_name;"""


def connect_with_mysqldb(database_host: str, database: str, custom_query: str) -> str:
    try:
        db_connection = mysql.connector.connect(option_files=database_conf,
                                                option_groups="client",
                                                host=database_host,
                                                database=database)
        cursor = db_connection.cursor()
        cursor.execute(custom_query)
        results = cursor.fetchall()
        return results
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
    finally:
        if (db_connection.is_connected()):
            db_connection.close()
            cursor.close()


def get_game_data():
    game_data = connect_with_mysqldb(env_mysql_host, env_mysql_db, sql_game_engine)
    for data in game_data:
        game_name = data[0]
        game_link = str(data[1]).replace("https://{}/".format(s3_bucket), "").replace("/index.html", "")
        game_data_dict[game_name] = game_link


def create_spreadsheet(game: str, version:str, live_in: str, link: str):
    with open('{}_game_client_data.csv'.format(environment), 'a') as data_file:
        data_write = csv.writer(data_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        data_write.writerow([g_name, version, live_in, environment, link, ' '])


def get_from_s3(game: str, link: str):
    elements = link.split("/")
    live_version = elements[-1]
    g_path1 = "/".join(elements[:-1])
    g_path2 = "ags/release/{}".format(game.replace("_", ""))
    path_list = [g_path1, g_path2]
    for path in path_list:
        # can`t use boto3, because of file limit check
        s3_cmd_value = "'{print $4}'"
        s3_cmd = """aws s3 ls s3://{0}/{1} --recursive | awk -F"/" {2} | sort | uniq""".format(s3_bucket, path, s3_cmd_value)
        client_version = subprocess.check_output(s3_cmd, shell=True, encoding='utf-8').strip().split('\n')
        for version in client_version:
            version_list.add(version)
    for vers in version_list:
        if live_version == vers:
            live_in = "Yes"
            launch_link = "https://{0}/{1}".format(s3_bucket, link)
        else:
            live_in = "No"
            launch_link = " "
        create_spreadsheet(game, vers, live_in, launch_link)


def main():
    get_game_data()
    print(game_data_dict)
    with open('{}_game_client_data.csv'.format(environment), 'w') as data_file:
        data_write = csv.writer(data_file, delimiter=',', quotechar='"', quoting=csv.QUOTE_MINIMAL)
        data_write.writerow(['Game Name', 'Version', 'Live In', 'Environment', 'Launch Link', 'Known Issues'])
    for g_name, g_link in game_data_dict.items():
        get_from_s3(g_name, g_link)
        print(g_name)
        print(version_list)
        version_list.clear()


if __name__ == '__main__':
    main()
