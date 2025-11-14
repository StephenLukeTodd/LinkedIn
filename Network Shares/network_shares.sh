#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Proxmox: Set up a CIFS share on the host and bind it into every LXC container.

require() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Missing required command: $1" >&2; exit 1; }; }

require pct
require awk
require sed
require mount
require umount
require grep

[[ ${EUID:-$(id -u)} -eq 0 ]] || { echo "❌ Please run as root."; exit 1; }

echo "=== CIFS Bind Mount Setup for All LXC Containers ==="

# ---- Inputs ----
read -r -p "Mount IP address (e.g., 192.168.50.140): " MOUNT_IP
MOUNT_IP=${MOUNT_IP//[[:space:]]/}
[[ -n "$MOUNT_IP" ]] || { echo "Mount IP is required."; exit 1; }

read -r -p "Share path (e.g., /Public/plex): " SHARE_SUBPATH
[[ "$SHARE_SUBPATH" =~ ^/ ]] || SHARE_SUBPATH="/${SHARE_SUBPATH}"
SHARE_PATH="//${MOUNT_IP}${SHARE_SUBPATH}"

read -r -p "Mount name (used for host & container paths, e.g., plex): " MOUNT_NAME
MOUNT_NAME=${MOUNT_NAME:-plex}

read -r -p "Host mount point [/mnt/${MOUNT_NAME}]: " MOUNT_POINT
MOUNT_POINT=${MOUNT_POINT:-/mnt/${MOUNT_NAME}}

read -r -p "Container path [/mnt/${MOUNT_NAME}]: " CONTAINER_MOUNT_PATH
CONTAINER_MOUNT_PATH=${CONTAINER_MOUNT_PATH:-/mnt/${MOUNT_NAME}}

read -r -p "Credentials file path [/root/.smbcredentials]: " CREDENTIALS_FILE
CREDENTIALS_FILE=${CREDENTIALS_FILE:-/root/.smbcredentials}

# ---- Confirm plan ----
cat <<PLAN

Plan:
  CIFS source:        $SHARE_PATH
  Host mount point:   $MOUNT_POINT
  Credentials file:   $CREDENTIALS_FILE
  Container path:     $CONTAINER_MOUNT_PATH (in all LXC containers)
PLAN

read -r -p "Proceed? [y/N]: " PROCEED
[[ $PROCEED =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ---- Optional cleanup of existing config ----
echo "Checking for existing fstab entries and container bindings..."
FSTAB_ESC_MP=$(printf '%s' "$MOUNT_POINT" | sed 's/[\/&]/\\&/g')
FSTAB_ESC_SHARE=$(printf '%s' "$SHARE_PATH" | sed 's/[\/&]/\\&/g')

FSTAB_HITS=$(grep -n "[[:space:]]${FSTAB_ESC_MP}[[:space:]]" /etc/fstab || true)
if [[ -n "$FSTAB_HITS" ]]; then
  echo "⚠️  Found existing /etc/fstab entries for $MOUNT_POINT:"
  echo "$FSTAB_HITS"
  read -r -p "Remove these fstab entries? [y/N]: " REPLY_FSTAB
  if [[ $REPLY_FSTAB =~ ^[Yy]$ ]]; then
    umount "$MOUNT_POINT" 2>/dev/null || true
    # Remove any fstab lines that reference this mount point or this share path
    sed -i "/[[:space:]]${FSTAB_ESC_MP}[[:space:]]/d" /etc/fstab
    sed -i "/^${FSTAB_ESC_SHARE}[[:space:]]/d" /etc/fstab
    echo "✅ Cleared existing fstab entries for $MOUNT_POINT."
  else
    echo "ℹ️  Keeping existing fstab entries."
  fi
fi

# Scan containers for existing mp bindings
mapfile -t CTIDS < <(pct list | awk 'NR>1 {print $1}')
AFFECTED_CTS=()
for CTID in "${CTIDS[@]:-}"; do
  CONF="/etc/pve/lxc/${CTID}.conf"
  [[ -f "$CONF" ]] || continue
  if grep -Eq "^mp[0-9]+: .*${FSTAB_ESC_MP}|mp=$(printf '%s' "$CONTAINER_MOUNT_PATH" | sed 's/[\/&]/\\&/g')" "$CONF"; then
    AFFECTED_CTS+=("$CTID")
  fi
done

if [[ ${#AFFECTED_CTS[@]} -gt 0 ]]; then
  echo "⚠️  Found existing container mount bindings in: ${AFFECTED_CTS[*]}"
  read -r -p "Remove these existing container bindings now? [y/N]: " REPLY_CT
  if [[ $REPLY_CT =~ ^[Yy]$ ]]; then
    for CTID in "${AFFECTED_CTS[@]}"; do
      CONF="/etc/pve/lxc/${CTID}.conf"
      sed -i "/^mp[0-9]\+: .*${FSTAB_ESC_MP}/d" "$CONF"
      sed -i "/^mp[0-9]\+: .*mp=$(printf '%s' "$CONTAINER_MOUNT_PATH" | sed 's/[\/&]/\\&/g')/d" "$CONF"
      echo "🧹 Cleared mp bindings in container $CTID."
    done
  else
    echo "ℹ️  Keeping existing bindings."
  fi
fi

# ---- Ensure mount point and credentials ----
mkdir -p "$MOUNT_POINT"
mkdir -p "$(dirname "$CREDENTIALS_FILE")"

SMB_USER=""
SMB_PASS=""
if [[ -f "$CREDENTIALS_FILE" ]]; then
  echo "Found existing credentials file at $CREDENTIALS_FILE"
  # Try to read existing values
  SMB_USER=$(awk -F'=' '/^username=/{print $2}' "$CREDENTIALS_FILE" | tail -n1 || true)
  SMB_PASS=$(awk -F'=' '/^password=/{print $2}' "$CREDENTIALS_FILE" | tail -n1 || true)
  echo "Current username in file: ${SMB_USER:-<none>}"
  read -r -p "Reuse this credentials file as-is? [Y/n]: " REUSE
  if [[ ! $REUSE =~ ^[Nn]$ ]]; then
    # Optionally correct username
    read -r -p "Keep username '${SMB_USER:-<empty>}'? [Y/n]: " KEEP_USER
    if [[ $KEEP_USER =~ ^[Nn]$ ]]; then
      read -r -p "New SMB username: " SMB_USER
    fi
    # Optionally correct password
    read -r -p "Change password for '${SMB_USER}'? [y/N]: " CHANGE_PASS
    if [[ $CHANGE_PASS =~ ^[Yy]$ ]]; then
      read -s -r -p "Enter new SMB password: " SMB_PASS; echo
    fi
  else
    # Not reusing -> prompt for fresh values
    read -r -p "SMB username: " SMB_USER
    read -s -r -p "SMB password for '${SMB_USER}': " SMB_PASS; echo
  fi
else
  # No file -> create new
  read -r -p "SMB username: " SMB_USER
  read -s -r -p "SMB password for '${SMB_USER}': " SMB_PASS; echo
  echo "Creating credentials file at $CREDENTIALS_FILE"
  install -m 600 /dev/null "$CREDENTIALS_FILE"
fi

# Write (or rewrite) credentials if values are provided (idempotent)
if [[ -n "$SMB_USER" || -n "$SMB_PASS" ]]; then
  cat >"$CREDENTIALS_FILE" <<EOF
username=$SMB_USER
password=$SMB_PASS
EOF
fi
chmod 600 "$CREDENTIALS_FILE"

# ---- Add (de-duplicated) fstab entry and mount ----
# Remove stale lines for this mount point
sed -i "/[[:space:]]${FSTAB_ESC_MP}[[:space:]]/d" /etc/fstab

# Add the canonical entry if not present
if ! grep -qsE "^\s*$(printf '%s' "$SHARE_PATH" | sed 's/[\/&]/\\&/g')\s+${FSTAB_ESC_MP}\s+cifs" /etc/fstab; then
  echo "$SHARE_PATH  $MOUNT_POINT  cifs  credentials=$CREDENTIALS_FILE,iocharset=utf8,vers=3.0,uid=0,gid=0,file_mode=0777,dir_mode=0777,nofail,_netdev  0  0" >> /etc/fstab
fi

systemctl daemon-reload 2>/dev/null || true
mkdir -p "$MOUNT_POINT"

echo "Mounting $MOUNT_POINT..."
if mount "$MOUNT_POINT" 2>/dev/null; then
  echo "✅ Mounted $SHARE_PATH to $MOUNT_POINT"
else
  echo "⚠️  mount by mountpoint failed; trying direct source..."
  if mount -t cifs "$SHARE_PATH" "$MOUNT_POINT" -o "credentials=$CREDENTIALS_FILE,iocharset=utf8,vers=3.0,uid=0,gid=0,file_mode=0777,dir_mode=0777,_netdev" 2>/dev/null; then
    echo "✅ Mounted $SHARE_PATH to $MOUNT_POINT"
  else
    echo "❌ Failed to mount $SHARE_PATH to $MOUNT_POINT"
    echo "— fstab entries referencing CIFS (for debugging):"
    grep -n "cifs" /etc/fstab || true
    exit 1
  fi
fi

# ---- Bind into every container ----
CHANGED=()
for CTID in "${CTIDS[@]:-}"; do
  CONF="/etc/pve/lxc/${CTID}.conf"
  [[ -f "$CONF" ]] || continue

  if grep -q "$MOUNT_POINT" "$CONF"; then
    echo "CT $CTID: already has $MOUNT_POINT bound; skipping."
    continue
  fi

  # Ensure target path exists inside the container
  pct exec "$CTID" -- mkdir -p "$CONTAINER_MOUNT_PATH"

  # Find first free mpX slot
  for i in {0..31}; do
    if ! grep -q "^mp$i:" "$CONF"; then
      echo "mp$i: $MOUNT_POINT,mp=$CONTAINER_MOUNT_PATH" >> "$CONF"
      echo "CT $CTID: ➕ added as mp$i"
      CHANGED+=("$CTID")
      break
    fi
  done
done

# ---- Reboot only running containers we changed ----
if [[ ${#CHANGED[@]} -gt 0 ]]; then
  echo "Rebooting modified, running containers: ${CHANGED[*]}"
  for CTID in "${CHANGED[@]}"; do
    if pct status "$CTID" | grep -q running; then
      pct reboot "$CTID" || echo "⚠️  Failed to reboot CT $CTID"
    else
      echo "CT $CTID is stopped; not rebooted."
    fi
  done
fi

# ---- Verify inside containers (best-effort) ----
for CTID in "${CHANGED[@]:-}"; do
  if pct status "$CTID" | grep -q running; then
    pct exec "$CTID" -- bash -lc "ls -A '$CONTAINER_MOUNT_PATH' >/dev/null 2>&1" \
      && echo "CT $CTID: ✅ $CONTAINER_MOUNT_PATH reachable" \
      || echo "CT $CTID: ⚠️ $CONTAINER_MOUNT_PATH not accessible yet"
  fi
done

echo "🎉 Done."