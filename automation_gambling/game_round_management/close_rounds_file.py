#!/bin/python3

import sys
import os
import mysql.connector
import subprocess

database_conf = "/var/lib/jenkins/engine.cnf"


def create_normalized_game_cycle_list():
    global normalized_game_cycle_list
    with open("normalized_game_cycle_list.txt", "r") as f:
        normalized_game_cycle_list = f.read().splitlines()


def get_game_cycle_id(normalized_game_cycle_id: str) -> str:
    sql_game_cycle_id = "SELECT game_cycle_id FROM tx_normalized_game_cycle_key where normalized_game_cycle_id={}".format(normalized_game_cycle_id)
    cursor.execute(sql_game_cycle_id)
    results = cursor.fetchall()
    for code in results:
        game_cycle_id = code[0]
    print("game_cycle_id = {}".format(game_cycle_id))
    return game_cycle_id


def get_general_info(game_cycle_statement: str):
    global transaction_id
    global current_balance
    global to_player_id
    global game_id
    global session_id

    sql_general_info = "SELECT transaction_id, current_balance, to_player_id, game_id, session_id FROM tx_payment_journal where game_cycle_id='{}';".format(game_cycle_statement)
    cursor.execute(sql_general_info)
    results = cursor.fetchall()
    for code in results:
        transaction_id = code[0]
        current_balance = code[1]
        to_player_id = code[2]
        game_id = code[3]
        session_id = code[4]
    print("transaction_id = {}".format(transaction_id))
    print("current_balance = {}".format(current_balance))
    print("to_player_id = {}".format(to_player_id))
    print("game_id = {}".format(game_id))
    print("session_id = {}".format(session_id))


def get_player_guid():
    global player_guid
    sql_player_guid = "SELECT username FROM tx_player where player_id='{}';".format(to_player_id)
    cursor.execute(sql_player_guid)
    results = cursor.fetchall()
    for code in results:
        player_guid = code[0]
    print("playerGuid = {}".format(player_guid))


def get_play_ref(game_cycle_statement: str):
    global play_ref
    sql_play_ref = "SELECT normalized_game_cycle_id FROM tx_normalized_game_cycle_key where game_cycle_id='{}';".format(game_cycle_statement)
    cursor.execute(sql_play_ref)
    results = cursor.fetchall()
    for code in results:
        play_ref = code[0]
    print("playRef = {}".format(play_ref))


def get_contest_ref():
    global contest_ref
    sql_contest_ref = "SELECT param_value FROM tx_player_params where session_id={} and param_key='contestRef';".format(session_id)
    cursor.execute(sql_contest_ref)
    results = cursor.fetchall()
    for code in results:
        contest_ref = code[0]
    print("contestRef = {}".format(contest_ref))


def get_operator_token():
    global operator_token
    sql_operator_token = "select operator_token from tx_player_session where session_id={}".format(session_id)
    cursor.execute(sql_operator_token)
    results = cursor.fetchall()
    for code in results:
        operator_token = code[0]
    print("operator_token = {}".format(operator_token))


def get_game_type_ref():
    global game_type_ref
    sql_game_type_ref = "select short_code from core_game where game_id={}".format(game_id)
    cursor.execute(sql_game_type_ref)
    results = cursor.fetchall()
    for code in results:
        game_type_ref = code[0]
    print("gameTypeRef = {}".format(game_type_ref))


def parse_xml(xml_file: str):
    try:
        config_file = "{0}_{1}".format(normalized_game_cycle_id, xml_file)
        os.system("cp -p {0} {1}".format(xml_file, config_file))
        action = xml_file.replace(".xml","")
        curl_request = 'curl -X POST -H "Content-Type: text/xml;charset=UTF-8" -d @{0} https://pr-rgs.pa.parxcasino.com/tpgi'.format(config_file)
        print("===> Parsing {} file".format(config_file))
        if action == "FindPlayByRef":
            os.system("sed -i 's/TOKEN/{0}/g' {1}".format(operator_token, config_file))
            os.system("sed -i 's/PLAY_REF/{0}/g' {1}".format(play_ref, config_file))
            with open(config_file, 'r') as file:
                print(file.read())
            find_play_output = subprocess.check_output(curl_request, shell=True)
            with open("FindPlayByRef.txt", "w") as ref:
                ref.write(str(find_play_output))
            with open("OUTPUT_FindPlayByRef.txt", "a") as out:
                out.write("*** normalized_game_cycle_id = {}\n".format(normalized_game_cycle_id))
                out.write("--- {}\n".format(curl_request))
                out.write(str("{}\n".format(find_play_output)))
            print(find_play_output)
        else:
            os.system("sed -i 's/TOKEN/{0}/g' {1}".format(operator_token, config_file))
            os.system("sed -i 's/PLAY_REF/{0}/g' {1}".format(play_ref, config_file))
            os.system("sed -i 's/GAME/{0}/g' {1}".format(game_type_ref, config_file))
            os.system("sed -i 's/TRANSACTIONID/{0}/g' {1}".format(transaction_id, config_file))
            os.system("sed -i 's/NEW_CONTEST/{0}/g' {1}".format(new_c_ref, config_file))
            os.system("sed -i 's/NEW_PLAYER/{0}/g' {1}".format(new_p_guid, config_file))
            with open(config_file, 'r') as file:
                print(file.read())
            output = subprocess.check_output(curl_request, shell=True)
            with open("OUTPUT_FindPlayByRef.txt", "a") as out:
                out.write("--- {}\n".format(curl_request))
                out.write(str("{}\n".format(output)))
            print(output)
    except OSError as e:
        print("*** Error occurs: {}".format(sys.exc_info()[1]))


def get_new_refs():
    global new_c_ref
    global new_p_guid
    new_c_ref = os.popen("awk '{print $8}' FindPlayByRef.txt").read().rstrip()
    new_p_guid = os.popen("awk '{print $9}' FindPlayByRef.txt").read().rstrip()
    print(new_c_ref)
    print(new_p_guid)


def main():
    try:
        create_normalized_game_cycle_list()
        for normalized_game_cycle_id in normalized_game_cycle_list:
            db_connection = mysql.connector.connect(option_files=database_conf, option_groups="client", host="172.16.22.12", database="rgs_pa")
            cursor = db_connection.cursor()
            print("--------- Collecting information")
            print("*** normalized_game_cycle_id = {}".format(normalized_game_cycle_id))
            get_general_info(get_game_cycle_id(normalized_game_cycle_id))
            get_player_guid()
            get_play_ref(get_game_cycle_id(normalized_game_cycle_id))
            get_contest_ref()
            get_operator_token()
            get_game_type_ref()

            parse_xml("FindPlayByRef.xml")
            get_new_refs()
            parse_xml("FindContestByRef.xml")
            parse_xml("SubmitPlayAction.xml")
            parse_xml("CloseContest.xml")
            parse_xml("EnsureContest.xml")
    except mysql.connector.Error as e:
        print("--------- ERROR: {}".format(e.msg))
        exit()
    finally:
        if (db_connection.is_connected()):
            db_connection.close()
            cursor.close()
            print("--------- MySQL connection is closed")


if __name__ == '__main__':
    main()
