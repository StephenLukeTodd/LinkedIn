#!/bin/bash

# === Prompt for tunnel and zone names ===
read -p "Enter tunnel name [Homelab]: " TUNNEL_NAME
TUNNEL_NAME=${TUNNEL_NAME:-Homelab}

read -p "Enter zone name [boggywroggy.org]: " ZONE_NAME
ZONE_NAME=${ZONE_NAME:-boggywroggy.org}

# === Construct config path based on tunnel name ===
CONFIG_PATH="$HOME/.cloudflared/config-${TUNNEL_NAME}.yml"

if [ ! -f "$CONFIG_PATH" ]; then
  echo "❌ Config file not found: $CONFIG_PATH"
  exit 1
fi

# === Find most recent backup ===
BACKUP_FILE=$(ls -t "${CONFIG_PATH}.bak."* 2>/dev/null | head -n 1)

if [ -z "$BACKUP_FILE" ]; then
  echo "❌ No backup files found for rollback."
  exit 1
fi

echo "🗂 Found backup file: $BACKUP_FILE"

# === Extract tunnel ID and name for restart ===
TUNNEL_ID=$(grep "^tunnel:" "$BACKUP_FILE" | awk '{print $2}')
TUNNEL_NAME=$(grep "^tunnel:" "$BACKUP_FILE" | awk '{print $2}')
if [ -z "$TUNNEL_ID" ]; then
  echo "❌ Could not extract tunnel ID from backup."
  exit 1
fi

CONFIG_PATH="$HOME/.cloudflared/config-${TUNNEL_NAME}.yml"

# === Perform rollback ===
echo "🔁 Rolling back config to: $BACKUP_FILE"
if ! cp "$BACKUP_FILE" "$CONFIG_PATH"; then
  echo "❌ Failed to restore backup."
  exit 1
fi

# === Restart cloudflared if necessary ===
if pgrep cloudflared > /dev/null; then
  echo "⚠️ cloudflared is already running. Please restart the tunnel manually if needed."
else
  echo "🚀 Starting tunnel: $TUNNEL_ID"
  nohup cloudflared tunnel --config "$CONFIG_PATH" run "$TUNNEL_ID" > /tmp/cloudflared.log 2>&1 &
fi

echo "✅ Rollback complete."
echo "📄 Log: tail -f /tmp/cloudflared.log"