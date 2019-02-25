# MongoBURS

Mongo Backup and Restore for AWS and GCP

## About
This repo contains two Docker files, one for AWS and one for GCP. Both Dockerfile will build
a mongo image with utilities to perform a backup and restore on a mongo database. 

## Usage
### Backup
Run the container in your environment (typically on a cron) with the configured environment variables

### Restore
Run the container with the following arguments `restore $TIMESTAMP $COLLECTIONS`

|Argument|Format|Description|
|--------|------|-----------|
|TIMESTAMP|YYYY-MM-DDTHH-MM-SS (2019-01-01T12:42:04)|the date to restore the database from|
|COLLECTIONS|DB/Collection,... (test/test,test/test2)|the collections you wish to restore into the database| 


### Environment Variables

|ENV|Description|Required|
|---|-----------|--------|
|MONGO|a mongo connection string|[x]|
|BUCKET|the name of the bucket you want to backup the database to|[x]|
|AWS_ACCESS_KEY_ID|the aws key ID|[x] (AWS only)|
|AWS_SECRET_ACCESS_KEY|the aws secret key|[x] (AWS only)|
|AWS_REGION|the aws region|[x] (AWS only)|
|GOOGLE_CREDENTIALS_PATH|location of the service account JSON file|[x] GCP only|

***Note***
in addition to the `GOOGLE_CREDENTIALS_PATH` env var you will need to mount the credentials file into the container
