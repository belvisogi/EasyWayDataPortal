#!/bin/bash
# GitLab Backup Script
# Server: 80.225.86.168
# Purpose: Create and manage GitLab backups
# Documentation: docs/infra/gitlab-setup-guide.md

set -e

# Configuration
BACKUP_DIR=~/backups/gitlab
RETENTION_DAYS=7
DATE=$(date +%Y%m%d-%H%M%S)

echo "========================================="
echo "GitLab Backup Script"
echo "Date: $DATE"
echo "========================================="
echo ""

# Step 1: Create GitLab backup
echo "Step 1: Creating GitLab backup..."
docker exec easyway-gitlab gitlab-backup create STRATEGY=copy

# Step 2: Backup configuration files
echo "Step 2: Backing up configuration files..."
tar -czf $BACKUP_DIR/config-$DATE.tar.gz ~/gitlab/config

# Step 3: List backups
echo "Step 3: Current backups:"
docker exec easyway-gitlab ls -lh /var/opt/gitlab/backups | tail -5

# Step 4: Cleanup old backups
echo "Step 4: Cleaning up backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -type f -mtime +$RETENTION_DAYS -delete
docker exec easyway-gitlab find /var/opt/gitlab/backups -type f -mtime +$RETENTION_DAYS -delete

echo ""
echo "========================================="
echo "Backup Complete!"
echo "========================================="
echo "Backup location: $BACKUP_DIR"
echo "Configuration backup: config-$DATE.tar.gz"
echo ""
echo "To restore a backup:"
echo "  docker exec easyway-gitlab gitlab-backup restore BACKUP=TIMESTAMP"
echo "========================================="
