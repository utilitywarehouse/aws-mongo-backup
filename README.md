# MongoBURS

Mongo Backup and Restore for AWS and GCP

[![Docker Repository on Quay](https://quay.io/repository/utilitywarehouse/mongo-burs/status "Docker Repository on Quay")](https://quay.io/repository/utilitywarehouse/mongo-burs)

## About
This repo contains two Docker files, one for AWS and one for GCP. Both Dockerfile will build
a mongo image with utilities to perform a backup and restore on a mongo database. 

## Usage
if you have large collections it is advised you mount a PVC to the following directory `/backup/data` to avoid storage issues

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


## Examples
### AWS
```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  labels:
    app: a-mongo-backup
  name: a-mongo-backup
  namespace: your_namespace
spec:
  schedule: "@daily"
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: burs
              image: quay.io/utilitywarehouse/mongo-burs:v1.2.0
              env:
                - name: MONGO
                  valueFrom:
                    secretKeyRef:
                      key: backup.mongo.servers
                      name: a-mongo-backup-secrets
                - name: AWS_ACCESS_KEY_ID
                  valueFrom:
                    secretKeyRef:
                      key: aws.key
                      name: a-mongo-backup-secrets
                - name: AWS_SECRET_ACCESS_KEY
                  valueFrom:
                    secretKeyRef:
                      key: aws.secret
                      name: a-mongo-backup-secrets
                - name: AWS_REGION
                  value: eu-west-1
                - name: BUCKET
                  value: some-aws-bucket
              imagePullPolicy: Always
```

### GCP
```
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  labels:
    app: a-mongo-backup
  name: a-mongo-backup
  namespace: your_namespace
spec:
  schedule: "@daily"
  successfulJobsHistoryLimit: 1
  failedJobsHistoryLimit: 1
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
          containers:
            - name: burs
              image: quay.io/utilitywarehouse/mongo-burs:v1.2.0
              env:
                - name: MONGO
                  valueFrom:
                    secretKeyRef:
                      key: backup.mongo.servers
                      name: a-mongo-backup-secrets
                - name: GOOGLE_CREDENTIALS_PATH
                  value: /var/gcp/service_account.json
                - name: BUCKET
                  value: some-aws-bucket
              imagePullPolicy: Always
              volumeMounts:
                - mountPath: /var/gcp
                  name: creds
                  readOnly: true
          volumes:
            - name: creds
              secret:
                secretName: a-mongo-backup-secrets
                items:
                  - key: gcp.creds.json
                    path: service_account.json


```
