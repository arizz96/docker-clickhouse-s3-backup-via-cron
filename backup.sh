#!/bin/bash

echo "`date` ~~~~~~~~~~~ STARTING BACKUP ~~~~~~~~~~~~"
rm -f /tmp/backup.native.dump.bz2
echo "`date` Creating clickhouse dump"

CMD="clickhouse-client --host ${CHHOST} --query=\"SELECT * FROM ${CHTABLE} FORMAT Native\""
$BACKUP_PRIORITY $CMD > /tmp/backup.native.dump
echo "`date` Compressing dump"
$BACKUP_PRIORITY bzip2 /tmp/backup.native.dump

echo "`date` Uploading to S3"
/backup/s3upload.rb
echo "`date` Done!"
