#!/bin/python3

import sys
import os
import mysql.connector
import requests
import json
import time

database_conf = "engine.cnf"
round_list = ["48:401cc653-320c-4484-a6c0-1bf55c71d37e", "48:a9093e66-ac53-4e0e-bd5d-6ecc24ff503b", "48:128b8166-50ae-401b-8052-d26aecf20ed7", "48:dbe98a06-b25e-4466-828e-2d7d483f2703", "48:1618a1d8-12c2-4a5e-a4f8-185c0d0aa6c2", "48:ad435d93-b057-4eb7-8535-62ad352e1099", "48:1107559f-8617-420e-8b2a-e9470cbaddce", "48:7d0f2312-6256-4ef0-9dfd-0533f4c9f7e6", "48:f57a66d0-2a31-4a55-a8a4-c2d32f239b10", "48:9df9fdd7-aad3-4516-ae94-0c462713b3cb", "48:f8675eb2-a625-4eb0-a8b7-bf96159b2664", "48:29853a16-6341-46e3-b865-2e28791ac803", "48:b9da61d9-1604-477a-b7dc-aefc9c033b85", "48:02c0efd3-b8f0-4c3c-aa51-e9f5624f08c5", "48:167ea5a9-1d1e-4a7c-a323-239ea2b444b7", "48:7dd4e3b8-fb7c-4656-9f62-61723f7f3fe1", "48:e694a15a-b42d-482f-8a41-d902b25abb44", "48:1cf720ae-a696-42aa-9af1-4b8d924c437d", "48:6e9adb2e-c0c4-43c2-9b85-34c15c4947e6", "48:76ad7e67-0a0d-49ce-ac89-81093ad115c9", "48:ca4e747b-4fb0-413c-a632-a6ee30d7c795", "48:483a99ac-5b3a-45c3-afc8-ade3ea6ce8bf", "48:c03c47ea-fdc3-4fd5-8c00-929120afbcdd", "48:71986f5f-2a1b-4dc6-9e5e-7483c2aed6f1", "48:beb68b76-6b2e-4468-97ee-6f1b0a63512e", "48:f8690b31-7faa-4f49-9583-a52a56cd4be4", "48:6e551ec8-e8b5-4de6-8557-51ee4fbf72f7", "48:aee3527e-ec93-41dc-a175-c37bb082e880", "48:8ab53d09-199d-4cff-b5cd-e0f7fb45a183", "48:bad6f458-9316-4674-a34f-0ab8f1bba68f", "48:049a8876-1314-4f43-9c67-fcd43317da5e", "48:d488cdd1-200d-4dfe-b4b9-f66d5ad2665f", "48:9463b278-aea4-47ad-aea1-90ec274fea26", "48:820a0507-d29d-4c66-bf61-fb9c0c623e9b", "48:67129be7-14df-4977-9fd3-5e64260c048e", "48:682c582b-4c2e-4c6d-8bd2-8e4f1460a1dd", "48:e265ca3a-297b-4c18-8f67-d9defca8f65a", "48:1c9e7c66-a3ef-4a92-a1b2-064d4992a9e6", "48:838d4a9a-8f0f-484c-aec4-7ca13f10523a", "48:ee2f8494-b51d-41dc-a14a-3809860de384", "48:627341ee-312e-41cb-b60c-3634bfbea5a1", "48:d3030a61-b8b0-43bd-959b-483f26554a9b", "48:c5b45a9e-13ce-49c7-aeec-d25d273761d4", "48:5f94fbc0-42e2-448f-b3b2-9b0238000a9d", "48:1df8dafd-96c8-4fef-b1d3-2ee826c85d75", "48:1d01562a-c5e1-45b0-836d-5465bdc127e5", "48:b535071e-aead-4475-befd-4776a28e6981", "48:0764d393-0271-47cf-bb82-3d8becf51d82", "48:f6b65316-cd62-496e-9a30-beee5455803c", "48:9b8f7f2f-dbe7-4bed-9d8f-f36ee69a8343", "48:dc006ede-b25e-4c0b-bd38-6a465448dbe4", "48:351c6e0a-02b7-4477-8d5b-d8318ac040f8", "48:0d939a86-c12d-441b-a375-0c31cd1e3f4b", "48:bb954649-9c74-47e2-92e7-6954e91acf89", "48:53a05a29-08e8-464e-9fef-c7555810777f", "48:46cdd7c1-f875-4467-9d60-f6bf252ad200", "48:0bd29dfa-00e0-4f53-bb60-a2cf556e21d7", "48:aa057f0e-3ee4-4b9e-9966-13c37a426f75", "48:57cf53de-32a5-486a-9890-21c0f08da553", "48:b4de0ef2-897c-40c7-a8ec-bc3db90f0d6a", "48:87ea1108-a039-4a97-aa73-10b74169c9af", "48:4e42463b-e6a0-491f-8082-61938e1f581e", "48:a1d637c0-0f51-4c96-a604-d382fa8eb665", "48:4763ef22-3f08-4647-9570-5671ed78b404", "48:c3835908-efad-45a7-b1ed-677d2ba599cb", "48:16a15fca-4171-404c-aad6-b5c3c6bf0386", "48:b16b5ab7-2e06-4951-b987-c40ca6503afd", "48:604f16c4-211c-40aa-8f54-b530e155352f", "48:fbe94ec4-2e4b-454b-8f5a-979c7843dba0", "48:a6bcbd50-643e-4734-9036-9115e268b264", "48:c92b6ee6-f526-4791-b664-94e5e286b785", "48:5206a5f6-b92b-410d-a43b-5462f86a04ba", "48:9c13ba0e-e299-454d-a914-07ec5bf59a45", "48:790c9cd1-b778-4db7-bae8-9c1185e7e680", "48:a47dbd00-8aaf-4e6a-9c1a-2f7eedd40f7d", "48:edb36712-ec64-4e93-8f28-3e85fcaa061e", "48:94f944b7-c54c-4a85-8d76-1d6aad55d467", "48:be21eb48-2b0f-4929-80a8-6441a393c539", "48:c49e1ce0-176a-4861-8576-116c34c3f5f9", "48:5627d5d9-8fe7-4458-95b1-2b234e1ad4cb", "48:9072b537-a93c-41b6-b41d-4cd3d34fd35c", "48:57548217-e6df-4a04-bbe6-e5f141dcc29c", "48:ccd3809b-e28b-4c7b-9f9c-d721c6cfa19b", "48:51f5b81d-2a2e-4d39-be7f-58ddeae40c0c", "48:5d76cfd3-4259-48a6-ab8c-22365ef9330b", "48:6f80c8a5-d353-4859-b9d4-d1e226ae10e7", "48:4ae81330-9fef-4bc4-a075-9e511f7cf221", "48:4d348b0e-6b87-45e9-83b6-fe2bbf44971b", "48:77647194-c6ef-4f36-b4b8-ce51dc266421", "48:70bd066c-adda-4779-af58-b5383a4e588d", "48:019becce-e52b-46c3-b4e2-7b7f5bebf90c", "48:a8bf944d-4ac4-4cbd-8f55-b246b7df1a0f", "48:e6cb2a3b-b926-4585-b0cd-31cc0c2220f4", "48:3ad6b62e-6906-43d8-b950-dde0abcc6109", "48:0d3c98af-800b-4945-b5ed-e3f5ed07b9b1", "48:8337b72f-4f3f-4ef0-b5cc-e6f94b400557", "48:b8a9dafc-3f28-4e47-8ef4-5410001c0567", "48:b97399de-f6e8-409f-b89d-7cfcd5b3199c", "48:e516b130-6f93-4bab-a8bb-59586ed761f8", "48:b34e40e6-4a52-4cc3-88e9-f2dd37b795b4", "48:176418f2-c91d-4d22-8f27-32cb24a1b9e7", "48:844e5e18-44b9-4b50-b31f-e72c6f7678c4", "48:c6f8b953-d6a6-4a8e-ac09-9185fa3ad6c4", "48:ceb915fb-b12c-4a62-96f8-daf4efdb66b4", "48:18d8a86f-7bf5-4a01-b15c-7211a93ad3c7", "48:de6b0ae9-0194-466a-9738-cd0981330495", "48:c8cd33fe-395d-4de9-9977-14f7f0748071", "48:0b848343-77f3-4d86-9b36-2574f59f0750", "48:20f563e1-5781-4296-8b89-c2f35ef0150d", "48:ac368acb-5383-4a72-a957-4695f1ed5685", "48:47aed7a8-8e1b-4da4-bfb5-8d32f520d6a2", "48:c3864323-39f1-4d9b-8cba-cce277f3bbe5", "48:226e2eed-f99f-457b-9a90-a93bb82df1c1", "48:bcda47a3-b1fd-484c-9ad1-7140cecb2efe", "48:1067b6ef-1602-45f7-b313-474948dfc381", "48:eda38f4f-8c13-4a9b-9221-936e6d67cf5e", "48:588a8e35-6b01-4041-a9db-a42d09bace22", "48:437d1e2f-998a-45e2-8da9-70de5b50c805", "48:78dbd42e-8547-408c-9742-4737496fc7cf", "48:29cebef5-a58e-401b-8e4b-51eac1a0015b", "48:91465115-29bc-457b-85d5-d92576ce8c3b", "48:06c6f6f0-ca52-40da-a5b9-f17c070e8bcd", "48:f09e64ba-4d6a-48ca-9ef0-9df13052d1e2", "48:1faa555b-3010-4ae0-b46a-7bca639c6133", "48:4bd39f92-c5f0-42a3-b239-c5b4457fe9d1", "48:50bb5cd2-abee-4731-a726-d3f6e4ad746b", "48:61f0e3ae-d035-4c3b-ade0-bdaafb7e03eb", "48:2c13767d-c5a0-4158-9202-21b04e7b6b5d", "48:ccf00d3e-ce79-4a02-ab1d-8b642f64c833", "48:3e09e85c-095f-4c87-9e1e-38cfb3bc6ecf", "48:c8c4c842-2b29-49c6-a583-ae5fc5bdd387", "48:8751d4a1-5e04-48a2-a74e-f0aa00107a27", "48:2891cb03-931b-4b06-8b80-a45fb8530055", "48:c0015368-4528-4517-9cd1-cbb396786204", "48:cd40e6b7-4674-4445-94fe-6e419dcce4ff", "48:8a68e842-b939-46ca-9fa5-575da5c30cbf", "48:e6d6d9dd-985d-49b8-89ce-d217e0423dd2", "48:e9f2e346-f901-4721-a795-d9bf4dbe916c", "48:0518a702-1cb0-4841-872c-1c2760b12e36", "48:50a5a7fc-0c53-4b4e-9baf-0d341488e3b5", "48:98518203-09d4-4128-8b81-b2f8bf458c60", "48:21170222-92e7-43a4-bd70-6bcca213cab1", "48:106b9dec-b850-4922-8dfa-1b93eeb0dda7", "48:fe367209-ee52-4436-9095-b5575963ee4e", "48:f1c6d4ef-49cb-4f0e-a0a6-3aae1ae4ecd3", "48:1dfc1ffa-6c69-41ee-9311-58722e5375f6", "48:21d2a5cb-d808-46f6-8578-877a7300e9af", "48:9f0c7656-c5dd-4f9c-bb4d-7ddc75a708a6", "48:84997715-578c-4d80-84f4-be717851a9e8", "48:8ec9d8a2-0c68-4284-8fdb-7e085310d312", "48:cc860931-f3e3-4a29-bb0f-f2f462da869e", "48:906586ef-19e5-4b72-9ae3-26bc666ce8bc", "48:e49ec34a-3cff-4ab2-9422-4dce0bfc266c", "48:bf73d4bd-427a-40e5-b4f1-9e607c9907f4", "48:4a95138f-d2da-4a04-919a-842edd41ed3e", "48:c0fc7dbc-4b8d-4f9e-a9e3-3524715882e8", "48:35092057-adf8-4b34-a8ea-d35e38d2512c", "48:8f9bf780-ae20-4449-a0ee-f1e58b6adec4", "48:11500d5c-f0a6-417a-99eb-f826815f47fb", "48:c7b10d63-8742-49e0-ab11-4b4499df2a5c", "48:3ecfa4dd-a0cc-4a6f-b4a4-94d65f5ebf5b", "48:358afa36-4908-47db-b9e7-61817e9185b2", "48:72e4907f-a05d-470f-bc15-8c0a0f363887", "48:3fbf1b17-be1e-4995-a658-399b7371aa7e", "48:eb5d614e-d38b-4a84-8d47-05d21b13874e", "48:87fd8870-25c6-4025-b144-63e0119f5bd2", "48:a7a7b9fa-8366-44bc-a5a8-df95f3e4186c", "48:245d4bfa-aee6-4a1f-b21e-59b2ed23a212", "48:e450e8ac-4038-48c6-9373-2244489f251f", "48:3f06ecef-a783-4ae2-9e8e-372c8c21f99a", "48:c0e275d5-8208-4295-8ae1-4e52373444b9", "48:90baff2a-cc19-46e9-91b3-aef258d1f4b4", "48:a7e1c30b-096b-4bbd-aca4-e557a45bba8f", "48:5f8b24c0-5564-49ab-bdca-5ec52277c29e", "48:6934527f-ace8-442c-bb66-46312a93dca9", "48:aa72eb5e-57ad-4996-ac72-98d295185783", "48:954c2889-e949-48ab-a239-83a64a004988", "48:6bfa4988-e3b2-4096-889a-3c6b84496549", "48:11e6fe6f-d69a-47b2-86f9-2727a1a1a6c5", "48:015c818f-2b28-4b3a-a190-49ff027dc7a5", "48:29bcd1cd-46f3-41b0-b8c0-692c0e9cc204", "48:0022027c-7448-4230-8e99-782d293308ba", "48:9efffdc8-ff75-4e67-a1e9-603e33e084c9", "48:4b0e0a1e-a3c2-499d-b97d-49ffd96cfd47", "48:d7962dcd-4aa6-43f6-8956-655af17b7de0", "48:959601ed-5be2-4077-962c-6742c11a050b", "48:bbc3f452-971d-4971-a214-bdb4c0190d50", "48:2f3bca59-65e4-4006-bb4f-45f6412f7ddf", "48:278a7c36-b3bf-4bc4-81f5-ba1c4561b0ce", "48:0380ee38-aee4-48b5-81fa-85befcbc0600", "48:c79af220-7185-4396-be8c-cdae928c8e83", "48:63ec6baa-fbef-472b-8a8d-8309caa7e89e", "48:8c57a1a4-32d5-4937-a4b0-303d5a75cef4", "48:201819bc-7bef-400c-b725-e8830af2df86", "48:63cc6074-ee51-4764-9948-37fcbf7a12ea", "48:b44ca1bc-7ae1-4b76-b0af-fba3f0993ac6", "48:0191e859-e5f4-42bc-9f84-3d878aa973fa"]


def collect_db_data(game_cycle: str):
    global transaction_id
    global player_id
    global session_id
    global token
    global username

    sql_game_cycle = 'select transaction_id, from_player_id, session_id from tx_payment_journal where game_cycle_id="{}";'.format(game_round)
    cursor.execute(sql_game_cycle)
    result_table = cursor.fetchall()
    for collumn in result_table:
        transaction_id = collumn[0]
        player_id = collumn[1]
        session_id = collumn[2]
        sql_game_token = "select operator_token from tx_player_session where session_id={};".format(session_id)
        cursor.execute(sql_game_token)
        result_token = cursor.fetchall()
        for r_token in result_token:
            token = r_token[0]
        sql_game_username = "select username from tx_player where player_id={};".format(player_id)
        cursor.execute(sql_game_username)
        result_username = cursor.fetchall()
        for r_username in result_username:
            username = r_username[0]


def close_round(game_cycle: str):
    url_endpoint = "http://game/api/rest/v1/realtime/gameops/principal/cancelTransactions"
    headers = {"Content-type": "application/json"}
    json_data_dict = {}
    json_data_dict["gameCode"] = "rakin_bacon"
    json_data_dict["gameCycleId"] = game_cycle
    json_data_dict["transactionId"] = transaction_id
    json_data_dict["username"] = username
    json_data_dict["token"] = token
    json_data_dict["reason"] = "void"
    print("---Start---------------------------------------------------------------------------------------------")
    print("*** ROUND: {}".format(game_cycle))
    print("*** URL: {}".format(url_endpoint))
    print("*** HEADERS: {}".format(headers))
    print("*** JSON: {}".format(json_data_dict))
    response_post = requests.post(url=url_endpoint, data=json.dumps(json_data_dict), headers=headers, verify=False)
    print("*** OUTPUT: {}".format(response_post.text))
    print("---Finish---------------------------------------------------------------------------------------------")


def zero_credit(game_cycle: str):
    url_endpoint_zero = "http://game/api/rest/v1/realtime/gameops/principal/transaction"
    headers = {"Content-type": "application/json"}
    json_data_zero_dict = {}
    json_trans_dict = {}
    json_data_list = []
    json_trans_dict["transactionType"] = "CREDIT"
    json_trans_dict["transactionKey"] = "{}_C".format(game_cycle)
    json_trans_dict["amount"] = 0
    json_data_list.append(json_trans_dict)
    json_data_zero_dict["username"] = username
    json_data_zero_dict["token"] = token
    json_data_zero_dict["gameCode"] = "rakin_bacon"
    json_data_zero_dict["transactions"] = json_data_list
    json_data_zero_dict["completeBet"] = True
    json_data_zero_dict["gameCycleId"] = game_cycle
    print("---Start---------------------------------------------------------------------------------------------")
    print("*** ROUND: {}".format(game_cycle))
    print("*** URL: {}".format(url_endpoint_zero))
    print("*** HEADERS: {}".format(headers))
    print("*** JSON: {}".format(json_data_zero_dict))
    response_post_zero = requests.post(url=url_endpoint_zero, data=json.dumps(json_data_zero_dict), headers=headers, verify=False)
    print("*** OUTPUT: {}".format(response_post_zero.text))
    print("---Finish---------------------------------------------------------------------------------------------")


def main():
    try:
        db_connection = mysql.connector.connect(option_files=database_conf, option_groups="client")
        cursor = db_connection.cursor()
        print("*** Collecting information about issued rounds")

        for game_round in round_list:
            collect_db_data(game_round)
            close_round(game_round)
            zero_credit(game_round)
            time.sleep(5)
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        exit()
    finally:
        if (db_connection.is_connected()):
            db_connection.close()
            cursor.close()


if __name__ == '__main__':
    main()
