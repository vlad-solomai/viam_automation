#!/bin/python3

import os
import gzip
from sys import argv
from pymongo import MongoClient
from datetime import datetime
from datetime import timedelta
from bson.json_util import dumps
import boto3
from botocore.exceptions import ClientError
import time


ENVIRONMENT = argv[1]
MONGO_PRIMARY = argv[2]
MONGO_SECONDARY = argv[3]
TARGET_DATABASE = argv[4]
TARGET_COLLECTION = argv[5]
START_DATE = argv[6]
FINISH_DATE = argv[7]
DEL_CONFIRM = argv[8]
S3_BUCKET = "project.logs"


def connect_to_mongodb(action: str, query: str, mongo_host: str):
    try:
        password = os.environ["DB_PASSWD"]
        credentials = "mongodb://username:{1}@{0}:27017".format(mongo_host, password)
        connection = MongoClient(credentials)
        database = connection[TARGET_DATABASE]
        collection = database[TARGET_COLLECTION]
        if action == "count":
            row_count = collection.find(query).count()
            print(f"TOTAL COUNT OF DOCS: {row_count} STATES")
            return row_count
        elif action == "find":
            output = collection.find(query).sort('datetime', 1)
            return output
        elif action == "delete":
            print("Deleting docs from collection")
            limit_output = collection.find(query).sort('datetime', 1).limit(10000)
            for row in limit_output:
                collection.delete_one(row)
        connection.close()
    except Exception as e:
        print(e)


def send_to_s3(filename: str, path:str) -> bool:
    '''The function sends file to AWS S3 using jenkins credentials'''
    folder_path = f"{path}/{filename}"
    print(f"SENDING DUMP {filename} TO S3 {folder_path}")
    s3 = boto3.resource('s3')
    try:
        s3.meta.client.upload_file(
            Filename=filename,
            Bucket=S3_BUCKET,
            Key=folder_path
        )
        return True
    except ClientError as err:
        print("*** Error during uploading to s3: {}".format(err))
        return False


def check_existence(filename: str, path: str) -> str:
    s3 = boto3.resource('s3')
    my_bucket = s3.Bucket(S3_BUCKET)
    for object_summary in my_bucket.objects.filter(Prefix=path):
        s3_object_name = object_summary.key.split("/")[-1]
        if filename == s3_object_name:
            return "File exist"


def collect_dump(month: str):
    local_arc_dir = f"{ENVIRONMENT}/{month}"
    s3_arc_dir = f"{ENVIRONMENT}/mongo_archive/{TARGET_COLLECTION}/{month}"
    arc_file = f"{ENVIRONMENT}_{TARGET_COLLECTION}_{START_DATE}.json.gz"

    s3_file_status = check_existence(arc_file, s3_arc_dir)
    if s3_file_status == "File exist":
        print(f"Archive {arc_file} with data was already created")
    else:
        if not os.path.exists(local_arc_dir):
            os.makedirs(local_arc_dir)
        if os.path.exists(f"{local_arc_dir}/{arc_file}"):
            os.remove(f"{local_arc_dir}/{arc_file}")
        mongo_output = connect_to_mongodb("find", select_query, MONGO_SECONDARY)
        for json_str in mongo_output:
            json_bytes = f"{dumps(json_str)}\n".encode('utf-8')
            with gzip.open(f"{local_arc_dir}/{arc_file}", 'a') as archive:
                archive.write(json_bytes)
        os.chdir(local_arc_dir)
        send_to_s3(arc_file, s3_arc_dir)
        os.chdir("../..")


def main():
    while START_DATE != FINISH_DATE:
        date_format = datetime.strptime(START_DATE, '%Y-%m-%d')
        next_day = date_format + timedelta(days=1)
        date_month = datetime.strftime(date_format, '%Y-%m')
        next_date = datetime.strftime(next_day, '%Y-%m-%d')
        print(f"\n=== Working range: {START_DATE} - {next_date}")
        select_query = { 'datetime': {'$gte': START_DATE,'$lt': next_date} }
        docs_count = connect_to_mongodb("count", select_query, MONGO_PRIMARY)
        if docs_count > 0:
            collect_dump(date_month)
        else:
            print(f"NO STATES TO COLLECT FOR {START_DATE}")
        # Delete data from collection:
        if DEL_CONFIRM == "Yes":
            while docs_count > 0:
                connect_to_mongodb("delete", select_query, MONGO_PRIMARY)
                docs_count = connect_to_mongodb("count", select_query, MONGO_PRIMARY)
                time.sleep(20)
            print("All docs were removed")
        START_DATE = next_date


if __name__ == "__main__":
    main()
