#!/bin/bash

# Ensure jq is installed
if ! command -v jq >/dev/null 2>&1; then
  echo "❌ Error: 'jq' is not installed. Please install it first:"
  echo "   Debian/Ubuntu: sudo apt install jq"
  echo "   RedHat/CentOS: sudo yum install jq"
  echo "   macOS (brew): brew install jq"
  exit 1
fi

read -rp "Enter tunnel name [Homelab]: " TUNNEL_NAME_INPUT
TUNNEL_NAME="${TUNNEL_NAME_INPUT:-Homelab}"

read -rp "Enter zone name [boggywroggy.org]: " ZONE_NAME_INPUT
ZONE_NAME="${ZONE_NAME_INPUT:-boggywroggy.org}"

CREDENTIALS_DIR="${HOME}/.cloudflared"

# === Constants: subdomains and services ===
declare -A HOST_SERVICES=(
  ["nucproxiemoxie.boggywroggy.org"]="https://192.168.50.60:8006"
  ["optiproxiemoxie.boggywroggy.org"]="http://192.168.50.192:8006"
  ["plexnas.boggywroggy.org"]="http://192.168.50.169:32400"
  ["gamenas.boggywroggy.org"]="http://192.168.50.105:50001"
)

echo "🔐 Manual Cloudflare Global API Key Login"
read -rp "Enter your Cloudflare email: " CF_EMAIL
read -rsp "Enter your Cloudflare Global API Key: " CF_API_KEY
echo ""

# === Fetch zones associated with the account ===
echo "🔍 Fetching zones for the account..."
ZONES_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones" \
  -H "X-Auth-Email: $CF_EMAIL" \
  -H "X-Auth-Key: $CF_API_KEY" \
  -H "Content-Type: application/json")

if ! echo "$ZONES_RESPONSE" | grep -q '"success":true'; then
  echo "❌ Invalid email or API key, or insufficient permissions."
  exit 1
fi

ZONES_LIST=$(echo "$ZONES_RESPONSE" | jq -r '.result[] | "\(.id) \(.name)"')

if [ -z "$ZONES_LIST" ]; then
  echo "❌ No zones found for this account."
  exit 1
fi

echo "Available zones:"
echo "$ZONES_LIST"

# Automatically select zone with name "$ZONE_NAME"
CF_ZONE_ID=$(echo "$ZONES_LIST" | awk -v zone="$ZONE_NAME" '$2 == zone {print $1}')

if [ -z "$CF_ZONE_ID" ]; then
  echo "❌ Zone '$ZONE_NAME' not found."
  exit 1
fi

echo "Selected zone '$ZONE_NAME' with ID: $CF_ZONE_ID"

# === Validate Zone Access ===
echo "🔍 Validating zone access..."
RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID" \
  -H "X-Auth-Email: $CF_EMAIL" \
  -H "X-Auth-Key: $CF_API_KEY" \
  -H "Content-Type: application/json")

if ! echo "$RESPONSE" | grep -q '"success":true'; then
  echo "❌ Invalid email, API key or Zone ID, or insufficient permissions."
  exit 1
fi
echo "✅ Zone access validated."

# === Check for existing tunnels ===
echo "🔍 Retrieving existing tunnels..."
TUNNELS_RESPONSE=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts" \
  -H "X-Auth-Email: $CF_EMAIL" \
  -H "X-Auth-Key: $CF_API_KEY" \
  -H "Content-Type: application/json")

# Extract account ID from the first account listed
ACCOUNT_ID=$(echo "$TUNNELS_RESPONSE" | jq -r '.result[0].id')
if [ -z "$ACCOUNT_ID" ] || [ "$ACCOUNT_ID" == "null" ]; then
  echo "❌ Unable to retrieve account ID with provided credentials."
  exit 1
fi

# Get tunnels for the account
TUNNELS_LIST=$(curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/tunnels" \
  -H "X-Auth-Email: $CF_EMAIL" \
  -H "X-Auth-Key: $CF_API_KEY" \
  -H "Content-Type: application/json")

# Check if tunnel exists
TUNNEL_ID=$(echo "$TUNNELS_LIST" | jq -r --arg name "$TUNNEL_NAME" '.result[] | select(.name==$name) | .id')

if [ -z "$TUNNEL_ID" ]; then
  echo "🔨 Tunnel '$TUNNEL_NAME' not found. Creating tunnel..."
  CREATE_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/tunnels" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" \
    --data "{\"name\":\"$TUNNEL_NAME\"}")

  if ! echo "$CREATE_RESPONSE" | grep -q '"success":true'; then
    echo "❌ Failed to create tunnel."
    echo "$CREATE_RESPONSE"
    exit 1
  fi
  TUNNEL_ID=$(echo "$CREATE_RESPONSE" | jq -r '.result.id')
  echo "✅ Tunnel '$TUNNEL_NAME' created with ID: $TUNNEL_ID"
else
  echo "✅ Tunnel '$TUNNEL_NAME' exists with ID: $TUNNEL_ID"
fi

# === Generate credentials file for the tunnel ===
mkdir -p "$CREDENTIALS_DIR"
CREDENTIALS_PATH="$CREDENTIALS_DIR/$TUNNEL_ID.json"

if [ ! -f "$CREDENTIALS_PATH" ]; then
  echo "❌ Credentials file not found at $CREDENTIALS_PATH"
  echo ""
  echo "👉 On a machine with a browser, run:"
  echo "   cloudflared tunnel login"
  echo "   cloudflared tunnel token create $TUNNEL_NAME"
  echo ""
  echo "Then copy the file to this machine with:"
  echo "   scp ~/.cloudflared/$TUNNEL_ID.json <user>@<server>:$CREDENTIALS_PATH"
  echo ""
  exit 1
else
  echo "✅ Credentials file already exists at $CREDENTIALS_PATH"
fi

# === Generate cloudflared config with noTLSVerify ===
CONFIG_PATH="$CREDENTIALS_DIR/config-$TUNNEL_NAME.yml"
echo "📄 Writing cloudflared config to $CONFIG_PATH"

cat > "$CONFIG_PATH" <<EOF
tunnel: $TUNNEL_ID
credentials-file: $CREDENTIALS_PATH

ingress:
EOF

for hostname in "${!HOST_SERVICES[@]}"; do
  service=${HOST_SERVICES[$hostname]}
  cat >> "$CONFIG_PATH" <<EOF
  - hostname: $hostname
    service: $service
    originRequest:
      noTLSVerify: true

EOF
done

cat >> "$CONFIG_PATH" <<EOF
  - service: http_status:404
EOF

echo "✅ Config file created with noTLSVerify: true for all specified subdomains."

echo "🌐 Ensuring DNS records exist for tunnel endpoints..."
for hostname in "${!HOST_SERVICES[@]}"; do
  RECORD_RESPONSE=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
    -H "X-Auth-Email: $CF_EMAIL" \
    -H "X-Auth-Key: $CF_API_KEY" \
    -H "Content-Type: application/json" \
    --data "{
      \"type\":\"CNAME\",
      \"name\":\"$hostname\",
      \"content\":\"$TUNNEL_ID.cfargotunnel.com\",
      \"ttl\":1,
      \"proxied\":true
    }")
  echo "🆗 DNS record created or attempted for $hostname"
done

# === Restart the tunnel ===
echo "🔁 Restarting tunnel: $TUNNEL_NAME"
pkill cloudflared 2>/dev/null || true
nohup cloudflared tunnel --config "$CONFIG_PATH" run "$TUNNEL_ID" > /tmp/cloudflared.log 2>&1 &

echo "🚀 Tunnel is restarting in the background"
echo "📄 View logs: tail -f /tmp/cloudflared.log"