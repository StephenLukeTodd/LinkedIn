#!/bin/bash

# === CONFIGURATION ===
MOUNT_PATH="/mnt/Plex_Media"
CONTAINER_IDS=($(pct list | awk 'NR>1 {print $1}'))  # Auto-detect all containers

echo "📦 Checking access to $MOUNT_PATH in all containers..."
echo

for CTID in "${CONTAINER_IDS[@]}"; do
    echo "🔍 Checking container $CTID..."

    pct exec "$CTID" -- bash -c "ls $MOUNT_PATH &>/dev/null"
    if [ $? -eq 0 ]; then
        echo "✅ Container $CTID: Mount exists and is readable."
    else
        echo "❌ Container $CTID: Mount missing or unreadable at $MOUNT_PATH."
    fi

    echo
done

echo "✅ Finished mount checks."