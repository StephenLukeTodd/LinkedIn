#!/bin/bash
set -e

echo "Stopping SillyTavern service..."
sudo systemctl stop sillytavern.service || true

echo "Disabling SillyTavern service..."
sudo systemctl disable sillytavern.service || true

echo "Removing systemd service file..."
sudo rm -f /etc/systemd/system/sillytavern.service

echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Removing SillyTavern directory..."
sudo rm -rf /opt/sillytavern

echo "Removing Node.js and npm..."
sudo apt purge -y nodejs
sudo rm -rf /etc/apt/sources.list.d/nodesource.list
sudo rm -rf ~/.npm ~/.nvm ~/.node-gyp /usr/local/lib/node_modules

echo "Removing Git and curl..."
sudo apt purge -y git curl

echo "Cleaning up unused packages and cache..."
sudo apt autoremove -y
sudo apt autoclean

echo "SillyTavern and related packages have been fully uninstalled."
