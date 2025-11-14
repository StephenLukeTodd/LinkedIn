#!/bin/bash

# === CONFIG ===
BACKUP_DIR="/var/lib/vz/dump"

echo "⚠️ Deleting all .tar.zst, .csv, and .log files in $BACKUP_DIR..."
rm -v "$BACKUP_DIR"/*.tar.zst "$BACKUP_DIR"/*.csv "$BACKUP_DIR"/*.log

echo "✅ Cleanup complete. Backup directory is now clean."