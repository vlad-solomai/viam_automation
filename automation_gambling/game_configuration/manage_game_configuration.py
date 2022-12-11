#!/bin/python3

import sys
import os
import mysql.connector
from sys import argv


database_conf = "/var/lib/jenkins/engine.cnf"
game_name = argv[1]
operator_name_list = argv[2].split(",")
stakes_list = argv[3].split(",")
denoms_list = argv[4].split(",")


def collect_db_data(operator_name: str):
    global game_id
    global operator_id
    print("*** Collecting information about Game and Operator")
    sql_game_id = ("select game_id from core_game where game_name='{}'".format(game_name))
    sql_operator_id = ("select operator_id from core_operator where operator_name='{}'".format(operator_name))
    cursor.execute(sql_game_id)
    game_results = cursor.fetchall()
    for g_id in game_results:
        game_id = g_id[0]
    cursor.execute(sql_operator_id)
    operator_results = cursor.fetchall()
    for op_id in operator_results:
        operator_id = op_id[0]
    print("*** Game ID: {}".format(game_id))
    print("*** Operator ID: {}".format(operator_id))
    print("*** Stakes list: {}".format(stakes_list))
    print("*** Denoms list: {}".format(denoms_list))


def db_commit(action: str):
    cursor.execute(action)
    db_connection.commit()
    print("*** record(s) affected: ", cursor.rowcount)


def add_denomination_support():
    sql_support_denom = "update core_game set is_denom_supported=1 where game_id={};".format(game_id)
    print(sql_support_denom)
    db_commit(sql_support_denom)


def delete_stakes():
    sql_delete_stakes = "delete from core_game_stake where game_id={0} and operator_id={1};".format(game_id, operator_id)
    print(sql_delete_stakes)
    db_commit(sql_delete_stakes)


def delete_denoms():
    sql_delete_denoms = "delete from core_game_denomination where game_id={0} and operator_id={1};".format(game_id, operator_id)
    print(sql_delete_denoms)
    db_commit(sql_delete_denoms)


def update_stakes(list: List[str]):
    for stake in list:
        if stake.startswith('default'):
            sql_add_default_stake = """\
                insert into core_game_stake (game_id, stake, default_stake, operator_id,currency_id, vip)
                select a.game_id,{0} as stake,1 as default_stake, {1} as operator_id,c.currency_id,0 as vip from core_live_game a
                join core_currency c
                where a.operator_id={1} and a.game_id={2};""".format(int(stake.replace("default ", "")), operator_id, game_id)
            print(sql_add_default_stake)
            db_commit(sql_add_default_stake)
        else:
            sql_add_stake = """\
                insert into core_game_stake (game_id, stake, default_stake, operator_id,currency_id, vip)
                select a.game_id,{0} as stake,0 as default_stake, {1} as operator_id,c.currency_id,0 as vip from core_live_game a
                join core_currency c
                where a.operator_id={1} and a.game_id={2};""".format(int(stake), operator_id, game_id)
            print(sql_add_stake)
            db_commit(sql_add_stake)


def update_denoms(list: List[str]):
    for denom in list:
        if denom.startswith('default'):
            sql_add_default_denom = """\
                insert into core_game_denomination (game_id, operator_id,currency_id,denomination,is_default)
                select a.game_id,{1} as operator_id,c.currency_id,{0} as denomination,1 as is_default from core_live_game a
                join core_currency c
                where a.operator_id={1} and a.game_id={2};""".format(int(denom.replace("default ", "")), operator_id, game_id)
            print(sql_add_default_denom)
            db_commit(sql_add_default_denom)
        else:
            sql_add_denom = """\
                insert into core_game_denomination (game_id, operator_id,currency_id,denomination,is_default)
                select a.game_id,{1} as operator_id,c.currency_id,{0} as denomination,0 as is_default from core_live_game a
                join core_currency c
                where a.operator_id={1} and a.game_id={2};""".format(int(denom), operator_id, game_id)
            print(sql_add_denom)
            db_commit(sql_add_denom)


def main():
    try:
        db_connection = mysql.connector.connect(option_files=database_conf, option_groups="client")
        cursor = db_connection.cursor()
        for operator in operator_name_list:
            collect_db_data(operator)
            add_denomination_support()
            delete_stakes()
            update_stakes(stakes_list)
            delete_denoms()
            update_denoms(denoms_list)

    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        exit()
    finally:
        if (db_connection.is_connected()):
            db_connection.close()
            cursor.close()


if __name__ == '__main__':
    main()
