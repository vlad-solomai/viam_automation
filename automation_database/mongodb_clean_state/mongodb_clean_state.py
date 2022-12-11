#!/bin/python3

import os
import datetime
import mysql.connector
from sys import argv
from pymongo import MongoClient

MONGODB_URL = argv[1]
GAME_CYCLE_ID = argv[2]
ENVIRONMENT = argv[3]
BUILD_NUMBER = argv[4]
PERFORMER = argv[5]
TICKET = argv[6]


def collect_states(tx_key: str):
    global game_id
    global provider_id
    global username
    global operator_id
    state_dict = {}

    try:
        if tx_key != "":
            select_query = { "txKey":tx_key.split(":")[1] }
            output = collection.find(select_query)
            print("=== COLLECTION OF STATES FOR '{}' GAME CYCLE:".format(GAME_CYCLE_ID))
            for data in output:
                print(data)
                state_dict = dict(data)

            if not state_dict:
                print("=== THERE IS NOTHING TO CLEAN")
                exit()
                connection.close()
            else:
                game_id = state_dict["gameId"]
                provider_id = state_dict["providerId"]
                username = state_dict["username"]
                operator_id = state_dict["operatorId"]
        else:
            print("=== GAME CYCLE ID SHOULD NOT BE EMPTY")
            exit()
            connection.close()
    except Exception as e:
        print(e)


def clean_states():
    global states_count

    operator_default = int(str(operator_id).replace("-",""))
    nedative_operator = "-{}".format(operator_id)
    select_query = { "gameId":game_id,"providerId":provider_id,"username":username,"operatorId":operator_id }
    update_query = { "$set": { "operatorId": nedative_operator } }

    if operator_id == operator_default:
        updated_states = collection.update_many(select_query, update_query)
        states_count = updated_states.modified_count
        print("=== UPDATING STATES FOR '{}' GAME CYCLE:".format(GAME_CYCLE_ID))
        print("=== db.stateJournal.updateMany({0}, {1})".format(select_query, update_query))
        print(states_count, "states updated.")
        connection.close()
        update_devops_db()
    else:
        print("=== STATES ARE ALREADY CLEANED FOR '{}' GAME CYCLE".format(GAME_CYCLE_ID))
        exit()
        connection.close()


def update_devops_db():
    try:
        cnx = mysql.connector.connect(option_files=database_conf, option_groups="devops")
        cursor = cnx.cursor()
        print("*** Collecting information about cleaning process")
        cleaned_date = datetime.datetime.now()

        update_sql = ("INSERT INTO cleaned_rounds (ENVIRONMENT, date, GAME_CYCLE_ID, game_id, username, operator_id, PERFORMER, BUILD_NUMBER, states_count, TICKET) \
                      VALUES ('{0}', '{1}', '{2}', '{3}', '{4}', '{5}', '{6}', '{7}', \
                      '{8}', '{9}');".format(ENVIRONMENT, cleaned_date, GAME_CYCLE_ID, game_id, username, operator_id, PERFORMER, BUILD_NUMBER, states_count, TICKET))
        cursor.execute(update_sql)
        cnx.commit()
        print("*** Updating cleaned_rounds database")
        print("*** record(s) affected: ", cursor.rowcount)
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        exit()
    finally:
        if (cnx.is_connected()):
            cnx.close()
            cursor.close()
            print("*** MySQL connection is closed")


def main():
    database_conf = "/var/lib/jenkins/engine.cnf"
    mongodb_password = os.environ['MONGODB_PASSWORD']
    credentials = "mongodb://admin:{1}@{0}:27017".format(MONGODB_URL, mongodb_password)
    connection = MongoClient(credentials)
    database = connection["collection_name"]
    collection = database["stateJournal"]
    collect_states(GAME_CYCLE_ID)
    clean_states()
    print("=== RESULTS ===")
    collect_states(GAME_CYCLE_ID)


if __name__ == "__main__":
    main()
