#!/bin/bash
# Automated Backup Script for EC2

BACKUP_DIR="/home/ec2-user/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="phplogin_backup_$DATE.sql"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup database
echo "Creating database backup..."
docker exec phplogin_mysql mysqldump -u root -proot phplogin > "$BACKUP_DIR/$BACKUP_FILE"

# Compress backup
echo "Compressing backup..."
gzip "$BACKUP_DIR/$BACKUP_FILE"

# Keep only last 7 days of backups
echo "Cleaning old backups..."
find $BACKUP_DIR -name "*.sql.gz" -mtime +7 -delete

echo "Backup complete: $BACKUP_FILE.gz"

# Optional: Upload to S3
# aws s3 cp "$BACKUP_DIR/$BACKUP_FILE.gz" s3://your-bucket/backups/
