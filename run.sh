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

UTIL="aws s3"
CRYPTO="--sse AES256"
BUCKET_PREFIX="s3"

if [[ -z "${GOOGLE_CREDENTIALS_PATH}" ]];then

    if [[ -z "${AWS_ACCESS_KEY_ID}" ]];then
        echo "missing required AWS_ACCESS_KEY_ID env var"
        exit 1
    fi

    if [[ -z "${AWS_SECRET_ACCESS_KEY}" ]];then
        echo "missing required AWS_SECRET_ACCESS_KEY env var"
        exit 1
    fi

    if [[ -z "${AWS_REGION}" ]];then
        echo "missing required AWS_REGION env var"
        exit 1
    fi
else
    stat ${GOOGLE_CREDENTIALS_PATH}
    if [[ $? -ne 0 ]];then
        echo "invalid service account json location"
        exit 1
    fi
    UTIL="gsutil"
    CRYPTO=""
    BUCKET_PREFIX="gs"
    gcloud auth activate-service-account --key-file=${GOOGLE_CREDENTIALS_PATH}
    if [[ $? -ne 0 ]];then
        echo "unable to authenticate service account with google"
        exit 1
    fi
fi


function doBackup {

    TIMESTAMP=`date +%Y-%m-%dT%H-%M-%S`
    BACKUP_NAME="$TIMESTAMP.tar.gz"
    BUCKET_PATH="$BUCKET_PREFIX://$BUCKET/$BACKUP_NAME"

    ##
    # Create our mongo dump into a timestamped directory
    #
    mongodump --uri ${MONGO} -o ${TIMESTAMP}

    if [[ $? -ne 0 ]];then
     echo "Failed to create mongo dump!"
        exit 1
    fi

    ##
    # change directory to our data mount
    #

    ## package up the lot into a tar.gz
    tar -zcvf ${BACKUP_NAME} ${TIMESTAMP}
    rm -rf ${TIMESTAMP}
    ##
    # Move the backup to S3 or exit
    #
    $UTIL cp $CRYPTO ${BACKUP_NAME} ${BUCKET_PATH}

    if [[ $? -ne 0 ]];then
     echo "Failed to copy mongo dump to bucket ${BUCKET_PATH}"
        rm ${BACKUP_NAME}
        exit 1
    fi

    rm ${BACKUP_NAME}
    ##
    # Success
    #
    echo "Successfully created backup ${BACKUP_NAME}, available at ${BUCKET_PATH}"
}


function doRestore {
    BACKUP_NAME="${TIMESTAMP}.tar.gz"
    BUCKET_PATH="$BUCKET_PREFIX://$BUCKET/$BACKUP_NAME"
    mkdir -p restore

    $UTIL cp ${BUCKET_PATH} ${BACKUP_NAME}
    if [[ $? -ne 0 ]];then
     echo "Failed to copy mongo dump from bucket ${BUCKET_PATH}"
        exit 1
    fi
    tar -xzvf ${BACKUP_NAME}
    rm ${BACKUP_NAME}

    for i in $(echo ${COLLECTIONS} | sed "s/,/ /g")
    do
        DATABASE=$(echo ${i} | awk -F "/" '{print $1}')
        COLLECTION=$(echo ${i} | awk -F "/" '{print $2}')
        mkdir -p restore/${DATABASE}
        mv ${TIMESTAMP}/${i}.bson restore/${DATABASE}
        mv ${TIMESTAMP}/${i}.metadata.json restore/${DATABASE}
        echo ${i}
    done
    rm -rf ${TIMESTAMP}
    mongorestore --uri ${MONGO} --dir restore
    if [[ $? -ne 0 ]];then
     echo "Failed to restore mongo dump ${BUCKET_PATH}"
        rm -rf restore
        exit 1
    fi
    rm -rf restore
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