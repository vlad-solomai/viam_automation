#!/bin/python3

import sys
import os
import mysql.connector
import requests
import json


database_conf = "engine.cnf"
round_list = []
sql_game_cycle = """\
    SELECT distinct p.display_name, p.operator_id as operatorId, g.game_code as gameId, s.session_token as token, concat(substr(j.game_cycle_id,4),'.0') as transactionKey
    FROM tmp_gan  gan
    join tx_normalized_game_cycle_key n on gan.playref=n.normalized_game_cycle_id
    join tx_payment_journal j on n.game_cycle_id=j.game_cycle_id
    join core_game g on j.game_id=g.game_id
    join tx_player p  on j.from_player_id =p.player_id and player_id!=1
    join tx_player_session s on j.session_id=s.session_id;"""
sql_game_cycle_old = """\
    SELECT distinct p.username, p.operator_id as operatorId, g.game_code as gameId, s.session_token as token, concat(substr(j.game_cycle_id,4),'.0') as transactionKey
    FROM tmp_gan  gan
    join tx_normalized_game_cycle_key_old n on gan.playref=n.game_cycle_id
    left join tx_payment_journal j on n.transaction_id=j.transaction_id
    left join core_game g on j.game_id=g.game_id
    left join tx_player p  on j.from_player_id =p.player_id and player_id!=1
    left join tx_player_session s on j.session_id=s.session_id;"""


def collect_db_data(sql_query: str):
    cursor.execute(sql_query)
    result_table = cursor.fetchall()
    for collumn in result_table:
        username = collumn[0]
        operator_id = collumn[1]
        game_code = collumn[2]
        session_token = collumn[3]
        transaction_key = collumn[4]
        round_row = "{0},{1},{2},{3},{4}".format(username, operator_id, game_code, session_token, transaction_key)
        round_list.append(round_row)


def close_round(data: str):
    url_endpoint = "http://wallet-pp/rgs/rest/account/{}/transactionV2".format(data[0])
    headers = {"gameprovider": "48",
               "Content-type": "application/json"}
    json_data_dict = {}
    json_trans_dict = {}
    json_data_list = []
    json_trans_dict["transactionType"] = "CREDIT"
    json_trans_dict["transactionKey"] = str(data[4])
    json_trans_dict["amount"] = 0
    json_data_list.append(json_trans_dict)
    json_data_dict["operatorId"] = int(data[1])
    json_data_dict["gameId"] = int(data[2])
    json_data_dict["token"] = str(data[3])
    json_data_dict["completeBet"] = True
    json_data_dict["transactions"] = json_data_list
    print("---Start---------------------------------------------------------------------------------------------")
    print("*** ROUND: {}".format(round))
    print("*** URL: {}".format(url_endpoint))
    print("*** HEADERS: {}".format(headers))
    print("*** JSON: {}".format(json_data_dict))
    response_post = requests.post(url=url_endpoint, data=json.dumps(json_data_dict), headers=headers, verify=False)
    print("*** OUTPUT: {}".format(response_post.text))
    print("---Finish---------------------------------------------------------------------------------------------")


def main():
    try:
        db_connection = mysql.connector.connect(option_files=database_conf, option_groups="client")
        cursor = db_connection.cursor()
        print("*** Collecting information about issued rounds")
        collect_db_data(sql_game_cycle)
        collect_db_data(sql_game_cycle_old)
        for row in round_list:
            close_round(row.split(","))
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        exit()
    finally:
        if (db_connection.is_connected()):
            db_connection.close()
            cursor.close()


if __name__ == '__main__':
    main()
