#!/bin/bash

# === Cloudflare Tunnel Token Setup Script (Automated) ===
# Description: Prompts user to paste Cloudflare token JSON, saves it, and creates a config file automatically

set -e

# Prompt for tunnel ID and hostname
read -rp "Enter the Cloudflare Tunnel ID (e.g. ff2b3c09-a768-...): " TUNNEL_ID
read -rp "Enter the public hostname (e.g. proxmox.boggywroggy.org): " HOSTNAME
read -rp "Enter the local service address (e.g. http://127.0.0.1:8006): " SERVICE

DEST_DIR="$HOME/.cloudflared"
CREDENTIALS_FILE="$DEST_DIR/$TUNNEL_ID.json"
CONFIG_FILE="$DEST_DIR/config-$TUNNEL_ID.yml"

# Ensure directory exists
mkdir -p "$DEST_DIR"

# Prompt to paste JSON content of token
echo ""
echo "📋 Paste the full contents of your Cloudflare tunnel token JSON below. Press Ctrl+D when finished:"
cat > "$CREDENTIALS_FILE"
chmod 600 "$CREDENTIALS_FILE"

echo "✅ Token saved to: $CREDENTIALS_FILE"

# Generate config file
cat > "$CONFIG_FILE" <<EOF
tunnel: $TUNNEL_ID
credentials-file: $CREDENTIALS_FILE

ingress:
  - hostname: $HOSTNAME
    service: $SERVICE
    originRequest:
      noTLSVerify: true

  - service: http_status:404
EOF

chmod 600 "$CONFIG_FILE"
echo "✅ Config file created: $CONFIG_FILE"

# Output usage instructions
echo ""
echo "🔁 You can now run your tunnel with:"
echo "   cloudflared tunnel --config $CONFIG_FILE run $TUNNEL_ID"

echo ""
echo "📄 Or install as a service:"
echo "   sudo cloudflared service install"
echo "   sudo systemctl start cloudflared"