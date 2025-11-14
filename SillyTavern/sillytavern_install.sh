#!/usr/bin/env bash

# SillyTavern Installation Script for Debian/Ubuntu
# This script will install SillyTavern and configure it to run at startup.

# Exit on any error
set -e

# Variables (feel free to change INSTALL_DIR if needed)
RUNUSER="$USER"
USER_HOME="$HOME"
if [ "$EUID" -eq 0 ]; then 
  # If running as root (not recommended), try to get the invoking user instead
  if [ -n "$SUDO_USER" ]; then 
    RUNUSER="$SUDO_USER"
    USER_HOME="$(eval echo "~$SUDO_USER")"
  else
    echo "Please run this script as a normal user (with sudo privileges), not as root."
    exit 1
  fi
fi
INSTALL_DIR="$USER_HOME/SillyTavern"

# 1. Update package list and install git and curl (for cloning repo and installing NVM)
echo "Installing system dependencies (git, curl)..."
sudo apt-get update -y
sudo apt-get install -y git curl  # install Git (for cloning) and curl (for NVM installation)&#8203;:contentReference[oaicite:6]{index=6}&#8203;:contentReference[oaicite:7]{index=7}

# 2. Install Node.js via NVM (Node Version Manager)
if ! command -v node >/dev/null 2>&1; then
  echo "Installing Node.js using NVM..."
  # Download and run NVM installer script&#8203;:contentReference[oaicite:8]{index=8}
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash

  # Load NVM into this shell session
  export NVM_DIR="$USER_HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Install latest LTS version of Node.js&#8203;:contentReference[oaicite:9]{index=9}
  nvm install --lts
  nvm alias default 'lts/*'   # set LTS as default for new shells
fi

# 3. Clone the SillyTavern repository (release branch)&#8203;:contentReference[oaicite:10]{index=10}
if [ ! -d "$INSTALL_DIR" ]; then
  echo "Cloning SillyTavern repository (release branch) into $INSTALL_DIR ..."
  git clone -b release https://github.com/SillyTavern/SillyTavern.git "$INSTALL_DIR"
else
  echo "SillyTavern directory already exists at $INSTALL_DIR. Skipping git clone."
fi

# Change into the SillyTavern directory
cd "$INSTALL_DIR"

# 4. Install SillyTavern Node dependencies
echo "Installing SillyTavern dependencies (npm packages)..."
npm install --no-audit --no-fund --loglevel=error --no-progress --omit=dev

# 5. Configure SillyTavern for external access and enable features
echo "Configuring SillyTavern (enabling external access, autorun, extensions)..."
# Generate default config if it doesn't exist (should have been created by npm install step).
# Set server to listen on all interfaces for external connections&#8203;:contentReference[oaicite:11]{index=11}:
sed -i 's/^listen: *false/listen: true/' config.yaml
# Enable auto-opening in browser on launch&#8203;:contentReference[oaicite:12]{index=12} (if not already true):
sed -i 's/^autorun: *false/autorun: true/' config.yaml
# Enable extensions (allows use of SillyTavern extensions)&#8203;:contentReference[oaicite:13]{index=13}:
sed -i 's/^\(\s*enabled:\) *false/\1 true/' config.yaml 2>/dev/null || true  # (ignore if already true or if pattern not found)
# Disable IP whitelist mode to allow any LAN device (for simplicity, open access)&#8203;:contentReference[oaicite:14]{index=14}:
sed -i 's/^whitelistMode: *true/whitelistMode: false/' config.yaml
# Bypass security check since we're disabling whitelist (not recommended for internet exposure)&#8203;:contentReference[oaicite:15]{index=15}:
sed -i 's/^securityOverride: *false/securityOverride: true/' config.yaml

# 6. Set up systemd service for SillyTavern
SERVICE_FILE="/etc/systemd/system/sillytavern.service"
echo "Creating systemd service at $SERVICE_FILE ..."
sudo bash -c "cat > $SERVICE_FILE" <<EOF
[Unit]
Description=SillyTavern AI chat server
After=network.target

[Service]
Type=simple
User=$RUNUSER
WorkingDirectory=$INSTALL_DIR
ExecStart=/bin/bash -c 'source $USER_HOME/.nvm/nvm.sh && cd $INSTALL_DIR && NODE_ENV=production node server.js'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to pick up the new service, enable it to start on boot, and start it now
sudo systemctl daemon-reload
sudo systemctl enable sillytavern.service
sudo systemctl start sillytavern.service

# 7. (Optional) Adjust firewall to allow access on port 8000
if command -v ufw >/dev/null 2>&1; then
  echo "Checking firewall (ufw) settings..."
  sudo ufw allow 8000/tcp || true
fi

echo "SillyTavern installation and setup complete.
The server should now be running and accessible on port 8000.
You can open a browser on any device in your network and navigate to http://<HOST_IP>:8000 to use SillyTavern."
