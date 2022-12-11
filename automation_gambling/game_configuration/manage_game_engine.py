#!/bin/python3

import sys
import os
import mysql.connector
import xml.etree.ElementTree as ET
from sys import argv


remote_path = 'C:\\Games'
action = argv[1]
game_name = argv[2]
game_port = argv[3]
remote_user = argv[4]
remote_host = argv[5]
database_host = argv[6]
database = argv[7]
database_conf = "engine.cnf"


def get_db_data() -> str:
    global short_code
    try:
        cnx = mysql.connector.connect(option_files=database_conf,
                                      option_groups="client",
                                      host=database_host,
                                      database=database)
        cursor = cnx.cursor()
        print("*** Collecting information about Game Engine")
        query = ("select short_code from core_game where game_name='{}'".format(game_name))
        cursor.execute(query)
        results = cursor.fetchall()
        for code in results:
            short_code = code[0]
        print("*** Data was successfully collected")
        return short_code
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        exit()
    finally:
        if (cnx.is_connected()):
            cnx.close()
            cursor.close()
            print("*** MySQL connection is closed")


def execute_command(command: str):
    for ip in remote_host.split(","):
        print("*** Going to {0} {1} on {2} server".format(command, game_name, remote_host))
        remote_action = '"{0}\\{1}_{3}\\game_wrapper.exe" {2}'.format(remote_path, short_code, command, game_port)
        os.system("ssh {0}@{1} {2}".format(remote_user, remote_host, remote_action))
        print("*** {} game - successfull!".format(command))

def main():
    get_db_data()
    if action == "restart":
        execute_command("stop")
        execute_command("start")
    elif action == "stop":
        execute_command(action)
    elif action == "start":
        execute_command(action)


if __name__ == '__main__':
    main()
