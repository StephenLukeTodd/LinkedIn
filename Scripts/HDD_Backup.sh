#!/bin/bash

set -e

# Rsync options
# -a: archive mode (recursive, preserves permissions/timestamps)
# -v: verbose
# -h: human-readable
# --progress: show progress
# --delete: remove files in the destination that no longer exist in the source
RSYNC_OPTS="-avh --progress --delete"

# Personal identifiers replaced with neutral variables:
# - Set MOUNT_UUID to your device UUID (if applicable)
# - The script uses the current user from the environment by default
USER_DIR="${USER:-user}"
MOUNT_UUID="<DEVICE_UUID>"   # replace with your device id if needed
MOUNT_BASE="/run/media/${USER_DIR}/${MOUNT_UUID}"
BACKUP_ROOT="/run/media/${USER_DIR}/Retro_Games"
PC_SOURCE="<HOME_DIR>/Documents/pcports"
CONFIG_SOURCE="<HOME_DIR>/.config"

echo "🔁 Syncing Emulation..."
rsync $RSYNC_OPTS "${MOUNT_BASE}/Emulation/" "${BACKUP_ROOT}/emulation/"

echo "🔁 Syncing PC Ports..."
rsync $RSYNC_OPTS "${PC_SOURCE}/" "${BACKUP_ROOT}/pcports/"

echo "🔁 Syncing Smash..."
rsync $RSYNC_OPTS "${MOUNT_BASE}/Smash/" "${BACKUP_ROOT}/smash/"

echo "🔁 Syncing .config directory..."
rsync $RSYNC_OPTS "${CONFIG_SOURCE}/" "${BACKUP_ROOT}/config_backup/"

echo "✅ All syncs complete."
