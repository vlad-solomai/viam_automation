#!/bin/python
import sys
import os
import datetime
import time
import mysql.connector
import xml.etree.ElementTree as ET
from sys import argv
import hashlib

script_version = "1.0.0"
script_location = "deploy_game_engine.py"
code_url = "git clone ssh://git-codecommit.eu-west-1.amazonaws.com/v1/repos/"
remote_path = 'C:\\Games'
game_name = argv[1]
engine_version = argv[2]
game_port = argv[3]
wallet_env = argv[4]
is_test = argv[5]
game_db_url = argv[6]
remote_user = argv[7]
remote_host = argv[8]
database_host = argv[9]
database = argv[10]
environment = argv[11]
build_numer = argv[12]
performer = argv[13]
is_webservice = argv[14]
database_conf = "/var/lib/jenkins/mysql_engine.cnf"
engines_dir = "game-engines/"
template_dir = "templates"


def clone_repo():
    try:
        if os.path.exists(engines_dir):
            os.chdir(engines_dir)
            os.system("git pull")
            print("*** Repository {} with Engines was successfully updated".format(engines_dir))
        else:
            clone = code_url + engines_dir
            os.system(clone)
            os.chdir(engines_dir)
            print("*** Repository {} with Engines was successfully downloaded".format(engines_dir))
    except OSError as e:
        print("*** ERROR: {}".format(sys.exc_info()[1]))
        exit()


def get_core_game_data(statement: str) -> List[str]:
    global game_path
    global short_code
    global game_url
    try:
        cnx = mysql.connector.connect(option_files=database_conf,
                                      option_groups="client",
                                      host=database_host,
                                      database=database)
        cursor = cnx.cursor()
        print("*** Collecting information about Game Engine")
        query = ("select short_code, mgs_code, desktop_launch_address from core_game where game_name='{}'".format(game_name))
        cursor.execute(query)
        results = cursor.fetchall()
        for code in results:
            short_code = code[0]
            mgs_code = code[1]
            game_url = code[2]
        game_path = "{0}_{1}".format(short_code, game_port)
        path = os.getcwd()
        engine_list = []
        for item in os.listdir(path):
            if not item.startswith('.git') and not item.startswith('template') and os.path.isdir(item):
                engine_list.append(item)
        if short_code not in engine_list:
            exit("*** There is no {} game in our repository".format(short_code))

        if statement == "collect":
            print("*** Data was successfully collected")
            return (game_path, short_code)
        elif statement == "update":
            if mgs_code == "" or mgs_code == None or game_port not in mgs_code.split():
                update_sql = ("update core_game set mgs_code=concat_ws(' ',mgs_code, {0}) where game_name='{1}'".format(game_port, game_name))
                cursor.execute(update_sql)
                cnx.commit()
                print("*** Updating {0} with {1} in database".format(game_name, game_port))
                print("*** record(s) affected: ", cursor.rowcount)
            else:
                print("*** Port {} already exist in database".format(game_port))
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        cleanup(game_path)
        exit()
    finally:
        if (cnx.is_connected()):
            cnx.close()
            cursor.close()
            print("*** MySQL connection is closed")


def get_sha1sum(sha1sum_target: str) -> str:
    try:
        sha1hash = hashlib.sha1(open("{0}/{1}".format(game_path, sha1sum_target),"rb").read()).hexdigest()
        return sha1hash
    except OSError as e:
        print("*** ERROR: {}".format(sys.exc_info()[1]))
        cleanup(game_path)
        exit()


def rename_engine_dir():
    try:
        os.system("cp -r {0}/{1}/ {2}".format(short_code, engine_version,  game_path))
        print("*** Directory {0} was renamed to {1}".format(game_name, game_path))
    except OSError as e:
        print("*** ERROR: {}".format(sys.exc_info()[1]))
        exit()


def parse_xml(xml_file: str):
    try:
        os.system("cp {0}/game_wrapper.* {1}".format(template_dir, game_path))
        print("*** Copying {0} file into {1} directory".format(xml_file, game_path))
        config_xml = "{0}/{1}".format(game_path, xml_file)

        print("===> Parsing {} file".format(config_xml))
        config_file_xml = ET.parse(config_xml)
        config_file_tree = config_file_xml.getroot()
        game_id_xml = config_file_tree.find("./id")
        game_name_xml = config_file_tree.find("./name")
        game_description_xml = config_file_tree.find("./description")
        game_executable_xml = config_file_tree.find("./executable")

        print("------- Inserting data about {} engine".format(game_name))
        game_id_xml.text = "{0}_{1}".format(short_code, game_port)
        game_name_xml.text = "{0}({1})".format(game_name, game_port)
        game_description_xml.text = "{} Engine".format(game_name)
        if os.path.exists("{0}/SocketServer.exe".format(game_path)):
            game_executable_xml.text = "C:\Games\{0}_{1}\SocketServer.exe".format(short_code, game_port)
        else:
            game_executable_xml.text = "C:\Games\{0}_{1}\{2}.exe".format(short_code, game_port, game_name.replace(" ", ""))

        config_file_xml.write(config_xml)
        print("------- id: {}".format(game_id_xml.text))
        print("------- name: {}".format(game_name_xml.text))
        print("------- description: {}".format(game_description_xml.text))
        print("------- executable: {}".format(game_executable_xml.text))
    except OSError as e:
        print("*** Error occurs: {}".format(sys.exc_info()[1]))
        cleanup(game_path)
        exit()


def parse_config(socket_config: str):
    try:
        config_file = "{0}/{1}".format(game_path, socket_config)
        if os.path.exists(config_file):
            print("===> Parsing {} file".format(config_file))
            print("------- Inserting data about {} engine".format(game_name))
            os.system("sed -i 's/AGSPORT/{0}/g' {1}".format(game_port, config_file))
            os.system("sed -i 's/AGSWALLET/{0}/g' {1}".format(wallet_env, config_file))
            if socket_config == 'appsettings.json':
                os.system("sed -i 's/AGSISTEST/{0}/g' {1}".format(is_test.lower(), config_file))
            else:
                os.system("sed -i 's/AGSISTEST/{0}/g' {1}".format(is_test, config_file))
            os.system("sed -i 's/AGSDATABASEURL/{0}/g' {1}".format(game_db_url, config_file))
            os.system("sed -i 's/AGSWEBSERVICE/{0}/g' {1}".format(is_webservice, config_file))
            print("------- DataBaseURL: {}".format(game_db_url))
            print("------- ServerPort: {}".format(game_port))
            print("------- WalletURL: {}".format(wallet_env))
            print("------- IsTest: {}".format(is_test))
            print("------- IsWebService: {}".format(is_webservice))
    except OSError as e:
        print("*** Error occurs: {}".format(sys.exc_info()[1]))


def copy_game_to_host():
    moving_stime = int(round(time.time()*1000))
    for ip in remote_host.split(","):
        print("*** Removing old version of {} engine".format(game_name))
        move_engine = '"move {0}\\{1}_{2}  {0}\\zzz_outdated_engines\\{3}_{1}_{2}"'.format(remote_path, short_code, game_port, moving_stime)
        print("ssh {0}@{1} {2}".format(remote_user, ip, move_engine))
        os.system("ssh {0}@{1} {2}".format(remote_user, ip, move_engine))

        print("*** Copying {0} to {1}:{2} server".format(game_path, ip, remote_path))
        scp_command = 'scp -r {0} {1}@{2}:"{3}"'.format(game_path, remote_user, ip, remote_path)
        scp_command_status = os.WEXITSTATUS(os.system(scp_command))
        if scp_command_status != 0:
            cleanup(game_path)
            exit("Copying process finished with status {}".format(scp_command_status))
        print("*** Game {} successfully copied to the server".format(game_name))


def execute_command(command: str):
    for ip in remote_host.split(","):
        print("*** Going to {0} {1} on {2} server".format(command, game_name, ip))
        remote_action = '"{0}\\{1}_{3}\\game_wrapper.exe" {2}'.format(remote_path, short_code, command, game_port)
        print("ssh {0}@{1} {2}".format(remote_user, ip, remote_action))
        os.system("ssh {0}@{1} {2}".format(remote_user, ip, remote_action))
        print("*** {} game - successfull!".format(command))


def get_gameengines_data():
    try:
        cnx = mysql.connector.connect(option_files=database_conf, option_groups="devops")
        cursor = cnx.cursor()
        print("*** Collecting information about Game Engine")
        artifact_list = []
        with open("{0}/criticalfiles.txt".format(game_path), "r") as criticalfiles:
            for line in criticalfiles:
                artifact_list.append(line.rstrip())
        artifact_data = datetime.datetime.now()
        game_version = game_url.split("/")[-2]

        for artifact in artifact_list:
            sha1sum_data = get_sha1sum(artifact)
            for ip in remote_host.split(","):
                update_sql = ("INSERT INTO deployments (Product, Date, Environment, Version, BuildNumber, URL, Artifact, MD5sum, Performer, Host) \
                              VALUES ('{0}', '{1}', '{2}', '{3}', '{4}', '{5}', '{6}', '{7}', \
                              '{8}', '{9}');".format(game_name, artifact_data, environment, game_version, build_numer, game_url, artifact, sha1sum_data, performer, ip))
                cursor.execute(update_sql)
                cnx.commit()
                print("*** Updating deployments database with {} artifact".format(artifact))
                print("*** record(s) affected: ", cursor.rowcount)
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        cleanup(game_path)
        exit()
    except IOError as e:
        print("*** ERROR: {}".format(sys.exc_info()[1]))
        cleanup(game_path)
        exit()
    finally:
        if (cnx.is_connected()):
            cnx.close()
            cursor.close()
            print("*** MySQL connection is closed")


def collect_script_sha1sum():
    try:
        cnx = mysql.connector.connect(option_files=database_conf, option_groups="devops")
        cursor = cnx.cursor()
        script_date = datetime.datetime.now()
        script_product = "Game Engine Deploy"
        script_artifact = script_location.split("/")[-1]
        script_sha1_select = "select MD5sum from deployments where Product='{0}' and Environment='{1}';".format(script_product, environment)
        cursor.execute(script_sha1_select)
        results = cursor.fetchall()
        if len(results)==0:
            for ip in remote_host.split(","):
                sha1sum_script = hashlib.sha1(open(script_location,"rb").read()).hexdigest()
                script_update_sql = ("INSERT INTO deployments (Product, Date, Environment, Version, Artifact, MD5sum, Performer, Host) \
                                      VALUES ('{0}', '{1}', '{2}', '{3}', '{4}', '{5}', '{6}', '{7}' \
                                      );".format(script_product, script_date, environment, script_version, script_artifact, sha1sum_script, performer, ip))
                cursor.execute(script_update_sql)
                cnx.commit()
                print("*** Updating deployments database with {} artifact".format(script_artifact))
                print("*** record(s) affected: ", cursor.rowcount)
        else:
            print("*** Artifact {} was found in database".format(script_artifact))
    except mysql.connector.Error as e:
        print("*** ERROR: {}".format(e.msg))
        cleanup(game_path)
        exit()
    except IOError as e:
        print("*** ERROR: {}".format(sys.exc_info()[1]))
        cleanup(game_path)
        exit()
    finally:
        if (cnx.is_connected()):
            cnx.close()
            cursor.close()
            print("*** MySQL connection is closed")


def cleanup(item: str):
    try:
        os.system("rm -rf {}".format(item))
        print("*** {} was successfully removed from workspace".format(item))
    except OSError as e:
        print("*** Error occurs: {}".format(sys.exc_info()[1]))
        exit()


def main():
    clone_repo()
    get_core_game_data("collect")
    rename_engine_dir()
    parse_xml("game_wrapper.xml")
    parse_config("SocketServer.exe.config")
    parse_config("appsettings.json")
    parse_config("{0}.exe.config".format(game_name.replace(" ", "")))
    execute_command("stop")
    execute_command("uninstall")
    copy_game_to_host()
    execute_command("install")
    execute_command("start")
    get_core_game_data("update")
    get_gameengines_data()
    collect_script_sha1sum()
    cleanup(game_path)


if __name__ == '__main__':
    main()
