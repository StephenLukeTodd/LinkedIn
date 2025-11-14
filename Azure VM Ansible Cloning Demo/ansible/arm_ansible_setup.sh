
#!/bin/bash

# Ensure we're running on an ARM Mac
if [ "$(uname -m)" != "arm64" ]; then
  echo "❌ This script is intended for ARM-based Macs (Apple Silicon)."
  exit 1
fi

# Define environment path
ENV_PATH="$HOME/.ansible_local_env"

echo "📦 Removing old environment (if any)..."
rm -rf "$ENV_PATH"

echo "📦 Creating Python virtual environment at $ENV_PATH..."
/opt/homebrew/bin/python3 -m venv "$ENV_PATH"

echo "🔧 Activating environment..."
source "$ENV_PATH/bin/activate"

echo "⬆️ Upgrading pip..."
pip install --upgrade pip setuptools wheel

echo "📥 Installing Ansible and required Azure SDK modules..."
pip install \
  ansible \
  azure-core \
  azure-identity \
  azure-mgmt-resource \
  azure-mgmt-compute \
  azure-mgmt-network \
  azure-mgmt-storage \
  azure-storage-blob \
  msrest \
  msrestazure

echo "📦 Installing Ansible Azure Collection..."
ansible-galaxy collection install azure.azcollection

echo "🛠️ Writing ansible.cfg to current folder..."
cat <<EOF > ansible.cfg
[defaults]
ansible_python_interpreter = $ENV_PATH/bin/python
collections_paths = $ENV_PATH/collections
EOF

echo "✅ Setup complete!"
echo "👉 To activate your environment:"
echo "   source $ENV_PATH/bin/activate"
echo "👉 Then run your playbook:"
echo "   ansible-playbook main_playbook.yml --check"

# source ~/.ansible_local_env/bin/activate