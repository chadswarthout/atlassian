#!/bin/bash

#With Atlassian Cloud rate limits, only can run once every 48 hours.

USERNAME=username
PASSWORD=apikey
INSTANCE=yoursite.atlassian.net
LOCATION="/atlassian-backups/"

### Checks for progress 3000 times every 20 seconds ###
PROGRESS_CHECKS=3000
SLEEP_SECONDS=20

# Set this to your Atlassian instance's timezone.
# See this for a list of possible values:
# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TIMEZONE=America/New_York

##----START-----###
echo "starting the script"

TODAY=$(TZ=$TIMEZONE date +%Y%m%d)
COOKIE_FILE_LOCATION=jiracookie

## The $BKPMSG variable will print the error message, you can use it if you're planning on sending an email
BKPMSG=$(curl -s --user "${USERNAME}:${PASSWORD}" -H "Accept: application/json" -H "Content-Type: application/json" https://${INSTANCE}/rest/backup/1/export/runbackup --data-binary '{"cbAttachments":"true", "exportToCloud":"true"}' )

##ADDED##
echo "message: $BKPMSG"


#Checks if the backup procedure has failed
if [ "$(echo "$BKPMSG" | grep -ic error)" -ne 0 ]; then
rm $COOKIE_FILE_LOCATION
echo "FAILED, IT RETURNED: $BKPMSG"
exit
fi

TASK_ID=$(curl -s --user "${USERNAME}:${PASSWORD}" -H "Accept: application/json" -H "Content-Type: application/json" https://${INSTANCE}/rest/backup/1/export/lastTaskId)

#Checks if the backup exists every 10 seconds, 2000 times. If you have a bigger instance with a larger backup file you'll probably want to increase that.
for (( c=1; c<=2000; c++ ))
do
PROGRESS_JSON=$(curl -s --user "${USERNAME}:${PASSWORD}" https://${INSTANCE}/rest/backup/1/export/getProgress?taskId=${TASK_ID})
FILE_NAME=$(echo "$PROGRESS_JSON" | sed -n 's/.*"result"[ ]*:[ ]*"\([^"]*\).*/\1/p')

##ADDED##
echo "$PROGRESS_JSON"

if [[ $PROGRESS_JSON == *"error"* ]]; then
break
fi

if [ ! -z "$FILE_NAME" ]; then
break
fi
sleep 10
done

#If after 2000 attempts it still fails it ends the script.
if [ -z "$FILE_NAME" ];
then
rm $COOKIE_FILE_LOCATION
exit
else

## PRINT THE FILE TO DOWNLOAD ##
echo "File to download: https://${INSTANCE}/plugins/servlet/${FILE_NAME}"

curl -s -L --user "${USERNAME}:${PASSWORD}" "https://${INSTANCE}/plugins/servlet/${FILE_NAME}" -o "$LOCATION/JIRA-backup-${TODAY}.zip"

fi
rm $COOKIE_FILE_LOCATION
