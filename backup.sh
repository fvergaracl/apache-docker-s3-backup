#!/bin/bash

# === Configuration ===
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="/tmp/apache_backup_${TIMESTAMP}.tar.gz"
SOURCE_DIR="/data"

# Check required environment variables
if [ -z "$S3_BUCKET" ]; then
  echo "[ERROR] Environment variable S3_BUCKET is not set. Aborting."
  exit 1
fi

# === Create backup ===
echo "[INFO] Creating backup from ${SOURCE_DIR}..."
tar -czf "$BACKUP_FILE" "$SOURCE_DIR"
if [ $? -ne 0 ]; then
  echo "[ERROR] Backup creation failed."
  exit 2
fi

# === Optional encryption with OpenSSL ===
if [ -n "$ENCRYPTION_PASS" ]; then
  echo "[INFO] ENCRYPTION_PASS detected. Encrypting backup with OpenSSL (AES-256-CBC)..."
  ENCRYPTED_FILE="${BACKUP_FILE}.enc"
  openssl enc -aes-256-cbc -salt -in "$BACKUP_FILE" -out "$ENCRYPTED_FILE" -pass pass:"$ENCRYPTION_PASS"
  if [ $? -ne 0 ]; then
    echo "[ERROR] Encryption failed."
    rm -f "$BACKUP_FILE"
    exit 3
  fi
  UPLOAD_FILE="$ENCRYPTED_FILE"
  rm -f "$BACKUP_FILE"
else
  UPLOAD_FILE="$BACKUP_FILE"
fi

# === Upload to S3 ===
echo "[INFO] Uploading $UPLOAD_FILE to $S3_BUCKET..."
aws s3 cp "$UPLOAD_FILE" "$S3_BUCKET/"
if [ $? -ne 0 ]; then
  echo "[ERROR] Upload to S3 failed."
  rm -f "$UPLOAD_FILE"
  exit 4
fi

# === Delete local file ===
rm -f "$UPLOAD_FILE"
echo "[INFO] Local backup file deleted."

# === Cleanup old backups in S3 (keep last 7) ===
echo "[INFO] Cleaning old backups in $S3_BUCKET (keep last 7)..."
BACKUPS_TO_DELETE=$(aws s3 ls "$S3_BUCKET/" | grep "apache_backup_" | sort | head -n -7 | awk '{print $4}')

for FILE in $BACKUPS_TO_DELETE; do
  echo "[INFO] Deleting old backup: $FILE"
  aws s3 rm "$S3_BUCKET/$FILE"
done

echo "[INFO] Backup process completed successfully."
