#!/bin/python
import sys
import os
import time
import datetime
import hashlib
from os import walk
import mysql.connector
from sys import argv
import json
import boto3
from botocore.exceptions import ClientError
import requests
from requests.exceptions import HTTPError


game_client = argv[1]
target_dir = argv[2]
backoffice_url = argv[3]
enable_forcing = argv[4]
version = argv[5].split("/")[1]
source_dir = argv[5].split("/")[0]
environment = argv[6]
build_numer = argv[7]
performer = argv[8]
bucket_name = "cdn.project.com"
database_conf = "/var/lib/jenkins/mysql_engine.cnf"


def get_db_data() -> List[str]:
    global client_s3_name
    global short_code
    global game_id
    try:
        cnx = mysql.connector.connect(option_files=database_conf,
                                      option_groups="client")
        cursor = cnx.cursor()
        print("*** Collecting information about Game")
        query = ("select short_code, game_id from core_game where game_name='{}'".format(game_client))
        cursor.execute(query)
        results = cursor.fetchall()
        for code in results:
            short_code = code[0].replace("_", "")
            game_id = code[1]
        client_s3_name = short_code.replace("social", "")
        print("*** Data was successfully collected")
        return (client_s3_name, short_code, game_id)
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        exit()
    finally:
        if (cnx.is_connected()):
            cnx.close()
            cursor.close()
            print("*** MySQL connection is closed")


def ensure_dir(dir_name: str):
    try:
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)
    except OSError as e:
        print("*** ERROR: {}".format(sys.exc_info()[1]))
        exit()


def cleanup(item: str):
    try:
        os.system("rm -rf {}".format(item))
        print("*** {} was successfully removed from workspace".format(item))
    except OSError as e:
        print("*** Error occurs: {}".format(sys.exc_info()[1]))
        exit()


def download_from_s3():
    ensure_dir(short_code)
    try:
        os.system("aws s3 cp s3://cdn.project.com/ags/{0}/{1}/{2}/ ./{3} --recursive".format(source_dir, client_s3_name, version, short_code))
    except OSError as e:
        print("*** Error during downloading from s3: {}".format(sys.exc_info()[1]))
        cleanup(short_code)
        exit()


def get_sha1sum(sha1sum_target: str) -> str:
    try:
        sha1hash = hashlib.sha1(open("{0}/{1}".format(client_s3_name, sha1sum_target),"rb").read()).hexdigest()
        return sha1hash
    except OSError as e:
        print("*** ERROR: {}".format(sys.exc_info()[1]))
        exit()

def update_devops_data(client_artifact: str):
    try:
        cnx = mysql.connector.connect(option_files=database_conf, option_groups="devops")
        cursor = cnx.cursor()
        print("*** Working with devops database")

        artifact_data = datetime.datetime.now()
        sha1sum_data = get_sha1sum(client_artifact)
        update_sql = ("INSERT INTO deployments (Product, Date, Environment, Version, BuildNumber, Artifact, MD5sum, Performer) \
                      VALUES ('{0} client', '{1}', '{2}', '{3}', '{4}', '{5}', '{6}', '{7}' \
                     );".format(game_client, artifact_data, environment, version, build_numer, client_artifact, sha1sum_data, performer))
        cursor.execute(update_sql)
        cnx.commit()
        print("*** Updating devops database with {} artifact".format(client_artifact))
        print("*** record(s) affected: ", cursor.rowcount)
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        exit()
    finally:
        if (cnx.is_connected()):
            cnx.close()
            cursor.close()
            print("*** MySQL connection is closed")


def modify_json():
    with open("{}/game-config.json".format(short_code), "r") as json_file:
        data = json.load(json_file)
        data["enableForcing"] = bool(enable_forcing)
    with open("{}/game-config.json".format(short_code), "w") as json_file:
        json.dump(data, json_file, sort_keys=True, indent=2)


def upload_to_s3() -> bool:
    print("*** Uploading {0} version:{1} to S3".format(game_client, version))
    s3 = boto3.resource('s3')
    try:
        engine_files = []
        total_file_count = 0
        total_file_size = 0
        for path, dirs, files in os.walk(short_code):
            for file in files:
                file_name = (os.path.join(path, file)).replace("{}/".format(short_code), "")
                size_file = os.path.getsize("{0}/{1}".format(short_code, file_name))
                engine_files.append(file_name)
                total_file_size += size_file
                total_file_count += 1
        print("    START TIME: {}".format(time.asctime()))
        print("    - Files to upload: {}".format(str(total_file_count)))
        print("    - Total size to upload: {}MB".format(int(total_file_size/1024/1024)))
        for f in engine_files:
            if f == "index.html":
                s3.meta.client.upload_file(
                    Filename="{0}/{1}".format(short_code, f),
                    Bucket=bucket_name,
                    Key="ags/{0}/{1}/{2}/{3}".format(target_dir, short_code, version, f),
                    ExtraArgs={"ContentType": "text/html"}
                )
            else:
                s3.meta.client.upload_file(
                    Filename="{0}/{1}".format(short_code, f),
                    Bucket=bucket_name,
                    Key="ags/{0}/{1}/{2}/{3}".format(target_dir, short_code, version, f)
                )
        print("    FINISH TIME: {}".format(time.asctime()))
        return True
    except ClientError as err:
        print("*** Error during uploading to s3: {}".format(err))
        return False


def invalidate_s3() -> bool:
    client = boto3.client('cloudfront')
    try:
        response = client.create_invalidation(
            DistributionId="E30T6SVV8C",
            InvalidationBatch={
                "Paths": {
                    "Quantity": 1,
                    "Items": [
                        "/ags/{0}/{1}/{2}/*".format(target_dir, short_code, version),
                    ]
                },
                "CallerReference": str(time.asctime())
            }
        )
        return True
    except ClientError as err:
        print("*** Error during invalidation: {}".format(err))
        return False
    finally:
        print("*** Data {0}/{1}/{2}/* was invalidated on s3.".format(target_dir, short_code, version))


def get_url(action: str) -> str:
    if action == "clearCache":
        url = "https://{0}/backoffice/{1}".format(backoffice_url, action)
    else:
        url = "https://{0}/backoffice/games/{1}/".format(backoffice_url, game_id)
    return url


def request_data():
    headers={"Authorization": "Basic 123asdluczo", # jenkins user pass from BO
             "Content-type": "application/json"
    }
    launch_address = "https://cdn.project.com/ags/{0}/{1}/{2}/index.html".format(target_dir, short_code, version)
    try:
        response_get = requests.get(get_url(game_id), headers=headers, verify=False) # verify=False, issue with ssl on NJ
        game_json = response_get.json()
        print("*** Changing Launch Adresses")
        game_json["desktopLaunchAddress"] = unicode(launch_address)
        game_json["mobileLaunchAddress"] = unicode(launch_address)
        print("    - DesktopLaunchAddress: {}".format(game_json["desktopLaunchAddress"]))
        print("    - MobileLaunchAddress: {}".format(game_json["mobileLaunchAddress"]))
        response_put = requests.put(get_url(game_id), headers=headers, verify=False, data=json.dumps(game_json)) # verify=False, issue with ssl on NJ
        response_post = requests.post(get_url("clearCache"), headers=headers, verify=False) # verify=False, issue with ssl on NJ
        print("*** Clean Cache: status {}".format(response_post.status_code))
    except HTTPError as http_err:
        print("*** HTTP error occurred: {}".format(http_err))
    except Exception as err:
        print("*** Other error occurred: {}".format(err))


def main():
    get_db_data()
    download_from_s3()
    update_devops_data("app-{}.js".format(version))
    update_devops_data("index.html")
    modify_json()
    upload_to_s3()
    request_data()
    invalidate_s3()
    cleanup(short_code)


if __name__ == '__main__':
    main()
