#!/bin/bash

filename="game_list.txt"
wrapper="wrapper.zip"

while IFS= read -r line; do
    gamename=$(echo $line | awk -F ": " '{print $1}')
    gameid=$(echo $line | awk -F ": " '{print $2}')

    if [ -f "${gamename}.zip" ]; then
        echo "*** '$gamename': START ***"
        echo " Creating '$gamename' game structure"
        $(mkdir -p ${gamename}/ios-launcher/ags/ ${gamename}/ios-launcher/ags/games/${gameid}/)

        echo " Installing '$wrapper' into '${gamename}/ios-launcher/ags/axsys/' directory"
        unzip -q $wrapper -d ${gamename}/ios-launcher/ags/

        echo " Installing '$gamename' into '${gamename}/ios-launcher/ags/games/${gameid}/' directory"
        unzip -q ${gamename}.zip -d ${gamename}/ios-launcher/ags/games/${gameid}/

        tree ${gamename} -f -L 5
        echo "*** '$gamename': DONE! ***"
    else 
        echo "No such archive: '$gamename'"
    fi
done < "$filename"
