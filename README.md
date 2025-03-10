# Apache Docker S3 Backup

A secure and automated backup system for Apache running in Docker containers. This setup performs daily volume backups, stores them in Amazon S3 with timestamped filenames, and retains only the latest 7 backups — ensuring reliable, consistent, and space-efficient offsite storage.

---

## 🔐 Key Features

- 🔄 **Daily automated backups** at a configurable time via cron.
- ☁️ **S3 integration** with timestamped archives.
- 🧹 **Retention policy**: Keeps only the latest 7 backups.
- 🔒 **Encryption-ready design** for secure data handling.
- ✅ **Containerized solution** using Docker Compose.
- 🔍 **Lightweight and extensible** backup container using AWS CLI.

---

## 💁️‍️ Project Structure

```
apache-docker-s3-backup/
├── apache-compose.yml       # Docker Compose configuration
├── backup.sh                # Backup + upload + cleanup script
├── entrypoint.sh            # Dynamically configures cron based on environment
├── crontab.txt              # (Deprecated) Cron schedule (now dynamically generated)
└── .env                     # AWS credentials and configuration
```

---

## ⚙️ Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/fvergaracl/apache-docker-s3-backup.git
cd apache-docker-s3-backup
```

### 2. Set AWS Credentials Securely

Create a `.env` file with your AWS credentials and backup settings:

```env
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
AWS_DEFAULT_REGION=your_aws_region  # e.g. us-east-1

# S3 Bucket for backups
S3_BUCKET=s3://your-backup-bucket-name

# Encryption settings (optional)
ENCRYPTION_PASS=your_encryption_pass

# Cron timing settings
CRON_MIN=0   # Minute (0-59)
CRON_HOUR=0  # Hour (0-23)
```

> ⚠️ **Important:** Add `.env` to `.gitignore` to prevent accidental leaks.

### 3. (Optional) Adjust Backup Schedule

Modify `CRON_HOUR` and `CRON_MIN` in `.env` to change the execution time.

### 4. Make Scripts Executable

```bash
chmod +x backup.sh entrypoint.sh
```

### 5. Start the Containers

```bash
docker compose -f apache-compose.yml up -d
```

---

## 📄 How It Works

1. **Apache volume** is mounted in both the Apache container and the backup container.
2. A cron job runs daily at the configured time (`CRON_HOUR:CRON_MIN`) to:
   - Compress `/data` into a `.tar.gz` file with a timestamp.
   - Upload it to the specified S3 bucket.
   - Automatically **delete old backups**, keeping only the most recent 7.
3. Logs are stored inside the backup container for debugging.

---

## 🔐 Security Recommendations

| Area                    | Recommendation                                                                                                            |
| ----------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| **AWS Credentials**     | Use `.env` (never commit keys). Prefer IAM roles if running in AWS EC2/ECS.                                               |
| **IAM Permissions**     | Use a minimal policy: `PutObject`, `ListBucket`, `DeleteObject` for the specific bucket.                                  |
| **Encryption**          | Enable **S3 bucket encryption** (SSE-S3 or SSE-KMS). Optionally, encrypt archives before upload using `openssl` or `gpg`. |
| **Container Isolation** | Avoid exposing the backup container externally. Limit permissions.                                                        |
| **Script Hardening**    | Validate uploads, sanitize file listings before deletion, restrict file permissions.                                      |
| **Restoration Testing** | Regularly test restoration from S3 to ensure backups are usable.                                                          |

---

## 🌍 Example IAM Policy for Backup User

```json
{
  "Effect": "Allow",
  "Action": [
    "s3:PutObject",
    "s3:GetObject",
    "s3:ListBucket",
    "s3:DeleteObject"
  ],
  "Resource": [
    "arn:aws:s3:::your-backup-bucket-name",
    "arn:aws:s3:::your-backup-bucket-name/*"
  ]
}
```

---

## 💌 Cron Logs (Optional)

You can view cron output using:

```bash
docker logs apache-backup
```

---

## 💡 Customization

| Task            | How                                                              |
| --------------- | ---------------------------------------------------------------- |
| Backup Time     | Modify `CRON_HOUR` and `CRON_MIN` in `.env`.                     |
| Retention Count | Change `head -n -7` in `backup.sh` to a different value.         |
| Backup Source   | Change the `/data` path if you're backing up a different volume. |

---

## 📀 Future Improvements (Suggestions)

- 📩 Add notification hooks (email, Slack, etc.) after successful/failed backups.
- 🔒 Add GPG encryption with secure passphrase storage.
- 🔄 Add restore script for easy disaster recovery.
- 📊 Add healthcheck monitoring or metrics reporting.

---

## 📚 License

MIT License — feel free to use, fork, and adapt.

---

## 👌 Contributing

Pull requests and ideas are welcome! Help improve this simple but powerful backup system.
