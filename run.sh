#!/bin/bash

TIMESTAMP=`date +%Y-%m-%dT%H-%M-%S`
BACKUP_NAME="$TIMESTAMP.dump.gz"
S3PATH="s3://$BUCKET/$BACKUP_NAME"

echo ${S3PATH}

if mongodump --uri=${MONGO} --gzip --archive=${BACKUP_NAME} && aws s3 cp ${BACKUP_NAME} ${S3PATH} && rm \${BACKUP_NAME} ;then
    echo "   > Backup succeeded"
else
    echo "   > Backup failed"
fi
echo "=> Done"