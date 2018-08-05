#!/bin/bash

#With Atlassian Cloud rate limits, only can run once every 48 hours.

USERNAME=username
PASSWORD=apikey
INSTANCE=yoursite.atlassian.net
LOCATION="/atlassian-backups/"

# Set this to your Atlassian instance's timezone.
# See this for a list of possible values:
# https://en.wikipedia.org/wiki/List_of_tz_database_time_zones
TIMEZONE=America/New_York
 
##----START-----###
echo "Starting the script..."

### PLEASE NOTICE THAT THE SESSION IS CREATED BY CALLING THE JIRA SESSION ENDPOINT!!! ######
#### THE SCRIPT DOES NOT WORK IF JIRA IS NOT INSTALLED !!! #######

## The $BKPMSG variable will print the error message, you can use it if you're planning on sending an email
BKPMSG=$(curl -s --user "${USERNAME}:${PASSWORD}" --header "X-Atlassian-Token: no-check" -H "X-Requested-With: XMLHttpRequest" -H "Content-Type: application/json"  -X POST https://${INSTANCE}/wiki/rest/obm/1.0/runbackup -d '{"cbAttachments":"true" }' )

 ## Checks if the backup procedure has failed
if [ "$(echo "$BKPMSG" | grep -ic backup)" -ne 0 ]; then
echo "FAILED, IT RETURNED $BKPMSG"
exit
fi

## Checks if the backup exists every 10 seconds, 2000 times. If you have a bigger instance with a larger backup file you'll probably want to increase that.
for (( c=1; c<=2000; c++ ))
do
PROGRESS_JSON=$(curl -s --user "${USERNAME}:${PASSWORD}" https://${INSTANCE}/wiki/rest/obm/1.0/getprogress.json)
FILE_NAME=$(echo "$PROGRESS_JSON" | sed -n 's/.*"fileName"[ ]*:[ ]*"\([^"]*\).*/\1/p')

##ADDED: PRINT BACKUP STATUS INFO ##
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
exit
else

## PRINT THE FILE TO DOWNLOAD ##
echo "File to download: $FILE_NAME"

curl -s -L --user "${USERNAME}:${PASSWORD}" "https://${INSTANCE}/wiki/download/$FILE_NAME" -o "$LOCATION/CONF-backup-${TODAY}.zip"


fi
