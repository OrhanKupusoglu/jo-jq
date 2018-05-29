#!/bin/bash

FILE_REPORT="report.json"
TEST_STATUS="fail"

# helper functions
usage () {
    echo "enter a status to filter:"
    echo "  --status=fail : <DEFAULT>"
    echo "  --status=success"
    echo "  --status=skip"
    echo
    echo "enter file to filter:"
    echo "  --file=report.json : <DEFAULT>"
    echo
    echo "get this help:"
    echo "  --help"
    echo
}

# check args
if [[ "$#" -gt 0 ]]
then
    while [ "$#" -gt 0 ]
    do
        case "$1" in
            --status=*)                 TEST_STATUS="${1#*=}"; shift 1;;
            --file=*)                   FILE_REPORT="${1#*=}"; shift 1;;
            --help)                     usage; exit 0;;
            --status|--file)            echo "ERROR: '$1' requires an argument, see --help"; exit 2;;
            *)                          echo "ERROR: argument '$1' is not supported."; exit 3;;
        esac
    done
fi

if [[ ! -e "$FILE_REPORT" ]]
then
    echo "ERROR - '$FILE_REPORT' - file does not exist"
    exit 1
fi

# read JSON
report_data=$(jq -n --slurpfile arr "${FILE_REPORT}" '$arr[0]')
filter_data=$(echo "${report_data}" | jq '.tests')
keys=($(echo "${filter_data}" | jq 'keys' | jq -r '.[]'))
len="${#keys[@]}"

if [[ $len -eq 0 ]]
then
    echo "WARNING: -- keys array is empty"
else
    number_total=0
    number_status=0

    #ver_id=$(echo "${report_data}" | jq ".tests [] .by_verification"  < report.json | jq keys[0] | head -1)
    #key_first="${keys[0]}"
    #ver_id=$(echo "${report_data}" | jq ".tests.\"${key_first}\".by_verification" | jq keys[0])
    ver_id=$(echo "${report_data}" | jq ".verifications" | jq keys[0])
    ver_id="${ver_id//\"}"
    printf "++ Verification ID:\n\t$ver_id\n"

    started_at=$(echo "${report_data}" | jq ".verifications.\"${ver_id}\".started_at")
    started_at="${started_at//\"}"
    printf "++ Test started at:\n\t$started_at\n"

    FILE_TIMESTAMP=$(date --date=$started_at +"%Y-%m-%d_%H-%M-%S")
    FILE_STATUS_TEXT="${TEST_STATUS}_${FILE_TIMESTAMP}.txt"
    FILE_STATUS_JSON="${TEST_STATUS}_${FILE_TIMESTAMP}.json"

    truncate --size 0 "${FILE_STATUS_TEXT}"

    for key in "${keys[@]}"
    do
        number_total=$((number_total+1))
        status=$(echo "${report_data}" | jq ".tests.\"${key}\".by_verification.\"${ver_id}\".status")
        status="${status//\"}"

        if [[ "$status" == "$TEST_STATUS" ]]
        then
            echo "$key" >> "${FILE_STATUS_TEXT}"
            number_status=$((number_status+1))
        else
            filter_data=$(echo "${filter_data}" | jq "del(.\"${key}\")")
        fi
    done

    echo "$filter_data" > $FILE_STATUS_JSON

    TIMESTAMP_COMPLETED=$( date +%s )
    TIME_DURATION="$(date -u -d "0 $TIMESTAMP_COMPLETED seconds - $TIMESTAMP_STARTED seconds" +"%H:%M:%S")"

    printf "++ Total tests:\n\t$number_total tests\n"
    printf "++ Status:\n\t$TEST_STATUS - $number_status tests\n"
    printf "++ Duration:\n\t$TIME_DURATION\n"
    printf "++ See:\n\t${FILE_STATUS_TEXT}\n\t${FILE_STATUS_JSON}\n\n"
fi

exit 0
