#!/bin/sh

# === Set defaults if not defined ===
CRON_MIN=${CRON_MIN:-0}
CRON_HOUR=${CRON_HOUR:-0}
CRON_LOG_FILE="/var/log/cron.log"

echo "[INFO] Using cron schedule: ${CRON_MIN} ${CRON_HOUR} * * *"

# === Make backup script executable ===
chmod +x /backup.sh

# === Create cron job dynamically ===
echo "${CRON_MIN} ${CRON_HOUR} * * * root /backup.sh >> ${CRON_LOG_FILE} 2>&1" > /etc/cron.d/apache-backup-cron

# === Set correct permissions ===
chmod 0644 /etc/cron.d/apache-backup-cron

# === Load cron job ===
crontab /etc/cron.d/apache-backup-cron

# === Start cron daemon in foreground ===
echo "[INFO] Starting cron..."
crond -f
