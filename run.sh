#!/bin/bash

##
# Make sure we can upload to an actual bucket
#
if [[ -z "${BUCKET}" ]];then
    echo "Missing required BUCKET env VAR"
    exit 1
fi


if [[ -z "${MONGO}" ]];then
    echo "Missing required MONGO env VAR"
    exit 1
fi


function doBackup {

    TIMESTAMP=`date +%Y-%m-%dT%H-%M-%S`
    BACKUP_NAME="$TIMESTAMP.tar.gz"
    S3PATH="s3://$BUCKET/$BACKUP_NAME"

    ##
    # Create our mongo dump into a timestamped directory
    #
    mongodump --uri ${MONGO} -o ${TIMESTAMP}

    if [[ $? -ne 0 ]];then
     echo "Failed to create mongo dump!"
        exit 1
    fi

    ## package up the lot into a tar.gz
    tar -zcvf ${BACKUP_NAME} ${TIMESTAMP}

    ##
    # Move the backup to S3 or exit
    #
    aws s3 cp --sse AES256 ${BACKUP_NAME} ${S3PATH}

    if [[ $? -ne 0 ]];then
     echo "Failed to copy mongo dump to AWS S3 bucket ${S3PATH}"
        exit 1
    fi
    ##
    # Success
    #
    echo "Successfully created backup ${BACKUP_NAME}, available at ${S3PATH}"
}


function doRestore {
    BACKUP_NAME="${TIMESTAMP}.tar.gz"
    S3PATH="s3://$BUCKET/$BACKUP_NAME"
    mkdir restore

    aws s3 cp ${S3PATH} ${BACKUP_NAME}
    if [[ $? -ne 0 ]];then
     echo "Failed to copy mongo dump from AWS S3 bucket ${S3PATH}"
        exit 1
    fi
    tar -xzvf ${BACKUP_NAME}

    for i in $(echo ${COLLECTIONS} | sed "s/,/ /g")
    do
        DATABASE=$(echo ${i} | awk -F "/" '{print $1}')
        COLLECTION=$(echo ${i} | awk -F "/" '{print $2}')
        mkdir -p restore/${DATABASE}
        mv ${TIMESTAMP}/${i}.bson restore/${DATABASE}
        mv ${TIMESTAMP}/${i}.metadata.json restore/${DATABASE}
        echo ${i}
    done
    mongorestore --uri ${MONGO} --dir restore
    echo "finished restore"
}


case $1 in
    restore)
        TIMESTAMP=$2
        COLLECTIONS=$3
        doRestore
    ;;
    *)
        doBackup
    ;;
esac