#!/bin/bash

set -e

DB_NAME="studentdb"
BACKUP_DIR="/var/backups/mongodb"
S3_BUCKET="YOUR_BUCKET_NAME"
S3_PATH="mongodb-backups"

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${DB_NAME}_${TIMESTAMP}.archive.gz"
LOCAL_FILE="${BACKUP_DIR}/${BACKUP_FILE}"
LOG_FILE="/var/log/mongodb-s3-backup.log"

echo "========================================" >> "$LOG_FILE"
echo "Backup started: $(date)" >> "$LOG_FILE"

/usr/bin/mongodump     --db="$DB_NAME"     --archive="$LOCAL_FILE"     --gzip

/usr/bin/aws s3 cp     "$LOCAL_FILE"     "s3://${S3_BUCKET}/${S3_PATH}/${BACKUP_FILE}"

find "$BACKUP_DIR"     -type f     -name "*.archive.gz"     -mtime +7     -delete

echo "Backup completed: $(date)" >> "$LOG_FILE"
echo "========================================" >> "$LOG_FILE"
