#!/bin/bash

STATUS=`curl --connect-timeout 3 -s -X POST -H "Content-Type: application/json" $1/rng/rngValues -d '{"ranges":[{"minRange":100,"maxRange":200,"quantity":3,"preventDuplicates":true}]}'`

if jq -e . >/dev/null 2>&1 <<<"$STATUS"; then
    RESPONSE=`echo $STATUS| jq -r '.rangeValues[].values[].value'`
        NUMBERS=(${RESPONSE})

#       NUMBERS[0]=99                           #change first number to less than 100 in response
#       NUMBERS[1]=299                          #change second number to greater than 200 in response
#       NUMBERS+=(122)                          #add additional number to response
#       NUMBERS[0]=${NUMBERS[1]}                #make first and second number equal

        if  [ ${#NUMBERS[@]} -eq 3 ] && [ ${NUMBERS[0])} -ge 100 ] && [ ${NUMBERS[1])} -ge 100 ] && [ ${NUMBERS[2])} -ge 100 ] && [ ${NUMBERS[0])} -le 200 ] && [ ${NUMBERS[1])} -le 200 ] && [ ${NUMBERS[2])} -le 200 ] && [ ${NUMBERS[0])} -ne ${NUMBERS[1])} ] && [ ${NUMBERS[0])} -ne ${NUMBERS[2])} ] && [ ${NUMBERS[1])} -ne ${NUMBERS[2])} ]; then
                # OK
                echo 1
        else
                # PROBLEM
                echo 0
        fi
else
    # PROBLEM
    echo 0
fi
