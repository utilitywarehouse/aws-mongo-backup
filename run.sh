#!/bin/bash

##
# Make sure we can upload to an actual bucket
#
if [[ -z "${BUCKET}" ]];then
    echo "Missing required BUCKET env VAR"
    exit 1
fi

TIMESTAMP=`date +%Y-%m-%dT%H-%M-%S`
BACKUP_NAME="$TIMESTAMP.dump.gz"
S3PATH="s3://$BUCKET/$BACKUP_NAME"


##
# Create our mongo dump or exit
#
mogodump --uri ${MONGO} --gzip --archive=${BACKUP_NAME} ||  echo "Failed to create mongo dump!" && exit 1
##
# Move the backup to S3 or exit
#
aws s3 cp --sse AES-256 ${BACKUP_NAME} ${S3PATH} || echo "Failed to copy mongo dump to AWS S3 bucket ${S3PATH}" && exit 1
##
# Success
#
echo "Sucessfully created backup ${BACKUP_NAME}, available at ${S3PATH}"