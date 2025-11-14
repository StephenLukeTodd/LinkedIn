#!/bin/bash

# Config
TAG="restored-from-mega"
LOG_FILE="/root/lxc_restore_log_$(date +%Y%m%d_%H%M%S).txt"
BACKUP_DIR="/var/lib/vz/dump"

# Check MEGA CMD
if ! command -v mega-login &> /dev/null; then
  echo "MEGA CMD not found. Please install MEGA CMD first."
  exit 1
fi

# Login
read -p "Enter MEGA Email: " mega_email
read -s -p "Enter MEGA Password: " mega_password
echo
mega-logout &>/dev/null
mega-login "$mega_email" "$mega_password"
if [ $? -ne 0 ]; then
  echo "Login failed. Exiting."
  exit 1
fi

# Ask for MEGA path
read -p "Enter MEGA folder (e.g., /ProxmoxBackups): " remote_dir
mkdir -p "$BACKUP_DIR"

echo "Downloading backups to $BACKUP_DIR..."
mega-get "$remote_dir" "$BACKUP_DIR"

if [ $? -ne 0 ]; then
  echo "Download failed. Exiting."
  mega-logout
  exit 1
fi

# Function to find next free VMID
get_next_free_vmid() {
  local id=$1
  while pct status "$id" &> /dev/null; do
    id=$((id + 1))
  done
  echo "$id"
}

# Restore loop
for file in "$BACKUP_DIR"/*.tar.lzo "$BACKUP_DIR"/*.vma.zst; do
  [ -e "$file" ] || continue

  filename=$(basename "$file")
  original_vmid=$(echo "$filename" | grep -oP 'vzdump-lxc-\K[0-9]+')

  if [ -z "$original_vmid" ]; then
    echo "Skipping $filename (no VMID found)"
    continue
  fi

  # Check if this file was already logged/restored
  if grep -q "$filename" "$LOG_FILE" 2>/dev/null; then
    echo "Skipping $filename (already in log)"
    continue
  fi

  # Check if a container already exists with original VMID
  if pct status "$original_vmid" &> /dev/null; then
    new_vmid=$(get_next_free_vmid "$original_vmid")
    echo "VMID $original_vmid exists. Restoring to new VMID: $new_vmid"
  else
    new_vmid="$original_vmid"
  fi

  echo "Restoring $filename to VMID $new_vmid..."
  if pct restore "$new_vmid" "$file" --storage local --force; then
    pct set "$new_vmid" -tags "$TAG"
    pct start "$new_vmid"
    echo "$(date): Restored $filename | Original VMID: $original_vmid | New VMID: $new_vmid | Tag: $TAG | Started" >> "$LOG_FILE"
    echo "VMID $new_vmid restored, tagged, and started."
  else
    echo "$(date): FAILED to restore $filename" >> "$LOG_FILE"
    echo "Failed to restore $filename"
  fi
done

mega-logout
echo "Finished. Log saved to $LOG_FILE"