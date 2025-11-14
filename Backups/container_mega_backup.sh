#!/bin/bash
PATH=/usr/sbin:/usr/bin:/bin

# Log all output for cron/systemd
exec > /var/log/container_mega_backup.log 2>&1
set -Eeuo pipefail
trap 'echo "❌ Error on line $LINENO: $BASH_COMMAND" >&2' ERR
set -x

echo "=== Starting container_mega_backup at $(date -Is) ==="
echo "UID: $(id -u) USER: $(id -un)"
echo "PATH: $PATH"
command -v pct || true
command -v vzdump || true
command -v mega-put || true
command -v mega-whoami || true

if [[ "$1" == "--dry-run-backup" ]]; then
    DRY_RUN_BACKUP=true
    echo "🔎 Dry run for backup enabled: will simulate backups without running vzdump or uploading."
else
    DRY_RUN_BACKUP=false
fi

# === Ensure MEGA CMD is installed ===
if ! command -v mega-put &> /dev/null; then
    echo "📦 Installing MEGA CMD for Debian 12..."
    wget https://mega.nz/linux/repo/Debian_12/amd64/megacmd-Debian_12_amd64.deb -O /tmp/megacmd.deb
    dpkg -i /tmp/megacmd.deb || apt-get install -f -y
fi

# === Ensure MEGA login session ===
if ! mega-whoami &> /dev/null; then
    echo "🔐 No active MEGA session found. Logging in..."
    if [ -f "/root/.mega_credentials" ]; then
        source /root/.mega_credentials
        mega-login "$MEGA_EMAIL" "$MEGA_PASSWORD"
    else
        echo "❌ MEGA credentials file not found at /root/.mega_credentials"
        exit 1
    fi
fi


# === CONFIG ===
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")
BACKUP_DIR="/var/lib/vz/dump"
MEGA_FOLDER="/ProxmoxBackups/$(hostname)"
CONTAINER_IDS=($(pct list | awk 'NR>1 {print $1}'))

# === Ensure backup dir exists ===
mkdir -p "$BACKUP_DIR"

# === Perform backups ===
HOSTNAME=$(hostname)
UPLOAD_LOG="${BACKUP_DIR}/${HOSTNAME}_upload_log_${TIMESTAMP}.log"
echo "Uploaded files to MEGA:" > "$UPLOAD_LOG"
for CTID in "${CONTAINER_IDS[@]}"; do
    CONTAINER_NAME=$(pct config "$CTID" | awk -F: '/^hostname:/ {print $2}' | xargs)
    if [[ -z "$CONTAINER_NAME" ]]; then CONTAINER_NAME="ct${CTID}"; fi
    
    # Delete previous backups of this container
    find "$BACKUP_DIR" -type f -name "${HOSTNAME}_${CONTAINER_NAME}_*.tar.zst" -not -name "*${TIMESTAMP}.tar.zst" -exec rm -f {} \;

    BACKUP_NAME="${HOSTNAME}_${CONTAINER_NAME}_${TIMESTAMP}.tar.zst"
    echo "📦 Backing up container $CTID as $BACKUP_NAME..."
    if [[ "$DRY_RUN_BACKUP" == true ]]; then
        echo "[Dry Run] Would run vzdump for container $CTID -> ${BACKUP_NAME}"
    else
        # Run vzdump to BACKUP_DIR using its default filename, then rename to our convention
        vzdump "$CTID" --dumpdir "$BACKUP_DIR" --compress zstd --mode snapshot
        LATEST_FILE=$(ls -1t "${BACKUP_DIR}"/vzdump-lxc-"${CTID}"-*.tar.zst 2>/dev/null | head -n1)
        if [[ -z "${LATEST_FILE:-}" || ! -f "$LATEST_FILE" ]]; then
            echo "❌ vzdump did not produce an output file for CTID $CTID"
            exit 1
        fi
        mv -f "$LATEST_FILE" "${BACKUP_DIR}/${BACKUP_NAME}"
    fi

    # === Upload to MEGA ===
    echo "☁️ Uploading backups to MEGA..."
    if [[ "$DRY_RUN_BACKUP" == true ]]; then
        echo "[Dry Run] Would ensure folder $MEGA_FOLDER exists"
        echo "[Dry Run] Would upload $BACKUP_NAME to $MEGA_FOLDER/"
    else
        if ! mega-ls "$MEGA_FOLDER" &> /dev/null; then
            mega-mkdir "$MEGA_FOLDER"
        fi
        mega-put "$BACKUP_DIR/$BACKUP_NAME" "$MEGA_FOLDER/"
    fi
    FILE_SIZE=$(stat -c%s "$BACKUP_DIR/$BACKUP_NAME")
    MOD_TIME=$(stat -c%y "$BACKUP_DIR/$BACKUP_NAME")
    if [[ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]]; then
        echo "❌ Expected backup file not found: $BACKUP_DIR/$BACKUP_NAME"
        exit 1
    fi
    echo " - $(basename "$BACKUP_DIR/$BACKUP_NAME") | ${FILE_SIZE} bytes | Modified: ${MOD_TIME}" >> "$UPLOAD_LOG"
done

# === Create CSV log ===
CSV_LOG="${BACKUP_DIR}/${HOSTNAME}_backup_log_${TIMESTAMP}.csv"
echo "container_id,container_name,backup_file,timestamp" > "$CSV_LOG"
for CTID in "${CONTAINER_IDS[@]}"; do
    CONTAINER_NAME=$(pct config "$CTID" | awk -F: '/^hostname:/ {print $2}' | xargs)
    echo "$CTID,$CONTAINER_NAME,$BACKUP_NAME,$TIMESTAMP" >> "$CSV_LOG"
done
if [[ "$DRY_RUN_BACKUP" == true ]]; then
    echo "[Dry Run] Would upload $CSV_LOG to $MEGA_FOLDER/"
else
    mega-put "$CSV_LOG" "$MEGA_FOLDER/"
fi
CSV_SIZE=$(stat -c%s "$CSV_LOG")
CSV_TIME=$(stat -c%y "$CSV_LOG")
echo " - $(basename "$CSV_LOG") | ${CSV_SIZE} bytes | Modified: ${CSV_TIME}" >> "$UPLOAD_LOG"

# === Log uploaded file names ===
echo "📄 Upload log written to $UPLOAD_LOG"
if [[ "$DRY_RUN_BACKUP" == true ]]; then
    echo "[Dry Run] Would upload $UPLOAD_LOG to $MEGA_FOLDER/"
else
    mega-put "$UPLOAD_LOG" "$MEGA_FOLDER/"
fi

# === Cleanup old local backups (optional, 3 days) ===
find "$BACKUP_DIR" -name '*.zst' -mtime +3 -delete

if [[ "$DRY_RUN_BACKUP" == true ]]; then
    echo "✅ Dry run for backup complete. No backups or uploads performed."
else
    echo "✅ Backup and upload complete."
fi

# === Install cron job verbose ===
install_cron_verbose() {
    CRON_CMD="/root/container_mega_backup.sh"
    CRON_JOB="0 2 * * 7 $CRON_CMD"
    # Remove existing job and add new one
    (crontab -l 2>/dev/null | grep -v "$CRON_CMD"; echo "$CRON_JOB") | crontab -
    echo "🕑 Cron job installed: $CRON_JOB"
    echo "📝 Current crontab entries:"
    crontab -l
}

dry_run_cron_job() {
    CRON_CMD="/root/container_mega_backup.sh"
    CRON_JOB="0 2 * * 7 $CRON_CMD"
    echo "[Dry Run] Would install cron job:"
    echo "$CRON_JOB"
}

if [[ "$1" == "--install-cron-verbose" ]]; then
    install_cron_verbose
    exit 0
elif [[ "$1" == "--dry-run-cron" ]]; then
    dry_run_cron_job
    exit 0
fi

# === Manual run confirmation ===
if [[ "$1" == "--run-now" ]]; then
    echo "🚀 Manual override: running backup now regardless of day/time."
elif [[ "$1" == "--dry-run-backup" ]]; then
    # Already handled above, continue script
    :
else
    echo "ℹ️  To run this backup script immediately (ignoring time restrictions), use:"
    echo "   ./container_mega_backup.sh --run-now"
    exit 0
fi