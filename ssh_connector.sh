#!/bin/bash

export NEWT_COLORS='
root=,black
window=,black
shadow=,black
textbox=brightgreen,black
border=brightgreen,black
button=brightgreen,black
actbutton=black,brightgreen
listbox=brightgreen,black
actlistbox=black,brightgreen
checkbox=brightgreen,black
actcheckbox=black,brightgreen
title=brightgreen,black
'

function create_list_of_envs () {
    basedir=$(dirname "$0")
    env_list=`ls -1 $basedir/host_list_* | sed "s/host_list_//" | sed 's/.*\///'`
    env_number=0
    body=""

    declare -A env_dict

    for env_name in ${env_list[@]}; do
        ((env_number++))
        env_dict["${env_number}"]="${env_name}"
        body+="$env_number    $env_name"$'\n'
    done

    environment_body=${body%$'\n'}

    environment_screen=$(whiptail --title  "SSH Connector center ¯\_(ツ)_/¯" \
    --fb --ok-button " Next " --cancel-button "Exit" \
    --separate-output --menu "Choose your environment:" $((20+${env_number})) 60 ${env_number} \
    ${environment_body} \
    3>&1 1>&2 2>&3)
    exitstatus=$?

    if [ $exitstatus = 0 ]; then
        create_list_of_hosts "$basedir/host_list_${env_dict["$environment_screen"]}"
    else
        echo -e "\n\033[1;31m SSH Conector Flow was finished...\033[0m\n"
        exit 0
    fi
}

function create_list_of_hosts () {
    whiptale_body_data=""
    host_count=`awk '{ print $0 }' $1 | wc -l`
    for line in $1; do
        ip_addr=`awk '{ print $1 "        " $2 }' ${line}`
        whiptale_body_data+="${ip_addr}"
    done

    whiptale_host=$(whiptail --fb --ok-button " Connect" --cancel-button "Back" \
    --separate-output --menu "Select reference host:" $((20+${host_count})) 60  ${host_count} \
    ${whiptale_body_data} 3>&1 1>&2 2>&3)
    whiptale_status=$?

    if [ $whiptale_status = 0 ]; then
        ssh ${whiptale_host}
    else
        create_list_of_envs
    fi
}

create_list_of_envs
