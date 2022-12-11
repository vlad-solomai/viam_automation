#!/bin/python3

import sys
import os
import mysql.connector
import datetime
from sys import argv
import requests
import json
from requests.exceptions import HTTPError
from slack import WebClient
from slack.errors import SlackApiError
import logging
logging.basicConfig(level=logging.DEBUG)


database_conf = "/var/lib/jenkins/engine.cnf"
operator_name_list = argv[1].split(",")
start_payment_date = argv[2]
finish_payment_date = argv[3]
game_cycle_file = "rounds.txt"
default_round_log = "round-close.log"
operator_id_list = []
search_list = ["| closed", "| not closed", "| game cycle is already in completed game cycle table"]
slack_channel = "#customer_support"


def collect_operator_id(operator_name: str) -> int:
    sql_operator_id = ("select operator_id from core_operator where operator_name='{}'".format(operator_name))
    cursor.execute(sql_operator_id)
    operator_results = cursor.fetchall()
    for op_id in operator_results:
        operator_id = op_id[0]
        return operator_id


def collect_game_cycle(operator_data: str):
    sql_game_cycle = """
        SELECT distinct(game_cycle_id) FROM tx_payment_journal a
        left join tx_completed_game_cycle b on a.game_cycle_id=b.payment_reference
        left join tx_player c on a.from_player_id=c.player_id
        where a.transaction_id>=(SELECT transaction_id FROM tx_payment_journal where payment_date >= '{0}' limit 1)
        and a.transaction_id<(SELECT transaction_id FROM tx_payment_journal where payment_date >= '{1}' limit 1)
        and a.to_player_id=1 and a.complete=1 and a.cancelled=0 and a.current_balance>0 and b.completed_tx_id is null 
        and c.operator_id={2};""".format(start_payment_date, finish_payment_date, operator_data)
    print(sql_game_cycle)
    cleanup(game_cycle_file)
    cursor.execute(sql_game_cycle)
    result_table = cursor.fetchall()
    for collumn in result_table:
        game_cycle = collumn[0]
        with open(game_cycle_file, "a") as rounds_list:
            rounds_list.write("{}\n".format(game_cycle))


def close_rounds(operator_id_close: int):
    try:
        if os.path.exists(game_cycle_file):
            print("*** Closing game rounds")
            cleanup(default_round_log)
            os.system("cp /var/lib/jenkins/devops-prod/scripts/close_rounds/application.properties .")
            os.system("java -jar /var/lib/jenkins/devops-prod/scripts/close_rounds/close-round.jar {0} {1}".format(game_cycle_file, operator_id_close))
        else:
            print("*** No rounds were collected from database, please check data.")
            open(default_round_log, "a").close()
    except OSError as e:
        print("*** Error occurs: {}".format(sys.exc_info()[1]))
        exit()


def notify_slack(operator_data: str, prev_date: str, now_date: str, pattern: str, pattert_count: str):
    slack_token = "xoxp-229522615970"
    client = WebClient(token=slack_token)
    user="jenkins-bot"
    try:
        if pattern == "game cycle is already in completed game cycle table":
            completed_pattern = "already closed"
            response = client.chat_postMessage(
                channel = slack_channel,
                text = """Finished processing issued rounds for {0} operator:
                        Period: {1} - {2}
                        Rounds {3}: {4}
                     """.format(operator_data.replace(" ", ""), prev_date, now_date, completed_pattern, pattert_count)
            )
        else:
            response = client.chat_postMessage(
                channel = slack_channel,
                text = """Finished processing issued rounds for {0} operator:
                        Period: {1} - {2}
                        Rounds {3}: {4}
                     """.format(operator_data.replace(" ", ""), prev_date, now_date, pattern, pattert_count)
            )
        if os.path.exists(filename):
            response = client.files_upload(
                channels = slack_channel,
                file = filename,
                title = custom_pattern
            )
    except SlackApiError as e:
        # You will get a SlackApiError if "ok" is False
        assert e.response["error"]  # str like 'invalid_auth', 'channel_not_found'
    except FileNotFoundError as e:
        print("*** Pattern for search was not found: {}".format(sys.exc_info()[1]))


def parse_log(message: str, operatorname: str):
    global total_pattert_count
    global custom_pattern
    global filename

    custom_pattern = message.replace("| ", "")
    if message == "| closed":
        filename = "Rounds_closed.log"
    elif message == "| not closed":
        filename = "Rounds_not_closed.log"
    elif message == "| game cycle is already in completed game cycle table":
        filename = "Rounds_already_closed.log"
    total_pattert_count = 0
    with open(default_round_log, "r") as log_file:
        for line in log_file:
            if message in line:
                total_pattert_count += 1
                with open(filename, "a") as closed_rounds:
                    closed_rounds.write(line)
    print("File was created: {}".format(filename))
    notify_slack(operatorname, start_payment_date, finish_payment_date, custom_pattern, total_pattert_count)
    cleanup(filename)


def cleanup(item: str):
    try:
        if os.path.exists(item):
            os.system("rm -rf {}".format(item))
            print("*** {} was successfully removed from workspace".format(item))
    except OSError as e:
        print("*** Error occurs: {}".format(sys.exc_info()[1]))
        exit()


def main():
    try:
        db_connection = mysql.connector.connect(option_files=database_conf, option_groups="client")
        cursor = db_connection.cursor()
        for operator in operator_name_list:
            print("Processing {} operator:".format(operator))
            collect_game_cycle(collect_operator_id(operator))
            close_rounds(collect_operator_id(operator))
            for search_pattern in search_list:
                parse_log(search_pattern, operator)

    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        exit()
    finally:
        if (db_connection.is_connected()):
            db_connection.close()
            cursor.close()
        cleanup(game_cycle_file)
        cleanup(default_round_log)


if __name__ == '__main__':
    main()
