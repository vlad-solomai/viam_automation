#!/bin/python3

import sys
import os
import mysql.connector
import requests
import json

round = "45A6436A-86AC-469E-8091-2424E1D01FCE,72,1,RSG-vpnpm8io0hxno0mzq2e21jyax9cw5xeho43x3xsox3zv707i23xw533vpooc0l2hzm4kwl6tlyp7uhxx8grr0jqdef2m6p8nfu09dkkjwqkpvha3y5fxo24fxhm5fxnh,5fb8c2f9-fed8-4477-8b47-b2281a111e86.0"


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
    close_round(round.split(","))


if __name__ == '__main__':
    main()
