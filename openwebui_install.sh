#!/bin/bash

set -e

echo "=== Updating and installing dependencies ==="
apt update && apt upgrade -y
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common

echo "=== Installing Docker ==="
# Add Docker’s official GPG key
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Enabling and starting Docker ==="
systemctl enable docker
systemctl start docker

echo "=== Pulling and running Open WebUI container ==="
docker run -d \
  --name open-webui \
  -p 3000:8080 \
  -v open-webui-data:/app/backend/data \
  --restart always \
  ghcr.io/open-webui/open-webui:main

echo "=== Open WebUI should now be running on port 3000 ==="
echo "Visit it via http://<LXC-IP>:3000"
