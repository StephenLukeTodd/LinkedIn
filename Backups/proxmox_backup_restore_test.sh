#!/bin/bash

# === Proxmox VE Backup, Restore, and Restore-Testing Script ===

# Variables
BACKUP_DIR="/root/proxmox_backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_ARCHIVE="/root/proxmox_backup_${TIMESTAMP}.tar.gz"
REMOTE_BACKUP_DIR="/mnt/remote_backup"  # <-- Adjust to your mounted storage if needed

# === Functions ===

backup_proxmox() {
    echo "📦 Starting Proxmox VE backup..."

    mkdir -p "$BACKUP_DIR"

    # Save installed packages
    dpkg --get-selections > "$BACKUP_DIR/package_list.txt"

    # Save APT sources
    cp -r /etc/apt "$BACKUP_DIR/apt"
    cp -r /etc/apt/trusted.gpg* "$BACKUP_DIR/apt/" || true

    # Save Proxmox and critical configs
    cp -r /etc/network "$BACKUP_DIR/network"
    cp /etc/hosts "$BACKUP_DIR/"
    cp /etc/resolv.conf "$BACKUP_DIR/"
    cp /etc/ssh/sshd_config "$BACKUP_DIR/"

    # Save user root configs
    cp /root/.bashrc "$BACKUP_DIR/" 2>/dev/null || true
    cp /root/.profile "$BACKUP_DIR/" 2>/dev/null || true

    # Save systemd custom services
    mkdir -p "$BACKUP_DIR/systemd"
    find /etc/systemd/system -name "*.service" -exec cp {} "$BACKUP_DIR/systemd/" \;

    # Save Proxmox cluster config database
    sqlite3 /var/lib/pve-cluster/config.db .dump > "$BACKUP_DIR/config_db_dump.sql"

    # Create compressed archive
    tar -czvf "$BACKUP_ARCHIVE" -C "$BACKUP_DIR" .

    rm -rf "$BACKUP_DIR"

    echo "✅ Backup complete: $BACKUP_ARCHIVE"

    upload_backup
}

restore_proxmox() {
    local archive="$1"
    if [[ ! -f "$archive" ]]; then
        echo "❌ Backup archive not found: $archive"
        exit 1
    fi

    echo "🛠️ Restoring Proxmox VE from $archive..."
    mkdir -p "$BACKUP_DIR"
    tar -xzvf "$archive" -C "$BACKUP_DIR"

    cp -r "$BACKUP_DIR/apt/"* /etc/apt/
    dpkg --set-selections < "$BACKUP_DIR/package_list.txt"
    apt-get update
    apt-get dselect-upgrade -y

    cp -r "$BACKUP_DIR/network/"* /etc/network/
    cp "$BACKUP_DIR/hosts" /etc/hosts
    cp "$BACKUP_DIR/resolv.conf" /etc/resolv.conf
    cp "$BACKUP_DIR/sshd_config" /etc/ssh/sshd_config

    cp "$BACKUP_DIR/.bashrc" /root/ 2>/dev/null || true
    cp "$BACKUP_DIR/.profile" /root/ 2>/dev/null || true

    cp "$BACKUP_DIR/systemd/"* /etc/systemd/system/
    systemctl daemon-reload

    # Restore Proxmox cluster database
    echo "⚙️ Restoring /var/lib/pve-cluster/config.db..."
    systemctl stop pve-cluster
    killall pmxcfs || true
    mv /var/lib/pve-cluster/config.db /var/lib/pve-cluster/config.db.bak || true
    sqlite3 /var/lib/pve-cluster/config.db < "$BACKUP_DIR/config_db_dump.sql"
    systemctl start pve-cluster

    rm -rf "$BACKUP_DIR"

    echo "✅ Restore complete. Manual reboot recommended."
}

upload_backup() {
    echo "☁️ Uploading backup archive to remote..."

    if [[ -d "$REMOTE_BACKUP_DIR" ]]; then
        cp "$BACKUP_ARCHIVE" "$REMOTE_BACKUP_DIR/"
        echo "✅ Upload successful: $REMOTE_BACKUP_DIR/"
    else
        echo "⚠️ Remote directory $REMOTE_BACKUP_DIR not found. Skipping upload."
    fi
}

test_restore() {
    echo "🧪 Starting Restore Test..."

    read -p "Enter the backup archive full path: " BACKUP_PATH
    if [[ ! -f "$BACKUP_PATH" ]]; then
        echo "❌ Backup file not found!"
        exit 1
    fi

    mkdir -p "$BACKUP_DIR"
    tar -xzvf "$BACKUP_PATH" -C "$BACKUP_DIR"

    read -p "Enter a unique VM ID for test (e.g., 999): " TEST_VM_ID
    read -p "Enter a name for test VM (e.g., test-restore-vm): " TEST_VM_NAME

    BACKUP_FILE=$(find "$BACKUP_DIR" -type f \( -name "*.vma" -o -name "*.vma.gz" \) | head -n1)
    if [[ -z "$BACKUP_FILE" ]]; then
        echo "❌ No VM backup file (.vma) found inside archive."
        rm -rf "$BACKUP_DIR"
        exit 1
    fi

    echo "Restoring test VM..."
    qmrestore "$BACKUP_FILE" "$TEST_VM_ID" --unique 1 --name "$TEST_VM_NAME"

    echo "Configuring test VM network..."
    qm set "$TEST_VM_ID" --net0 virtio,bridge=vmbr0,firewall=1

    qm start "$TEST_VM_ID"
    echo "✅ Test VM $TEST_VM_NAME (ID $TEST_VM_ID) started."

    read -p "Delete the test VM after inspection? (y/n): " DELETE_CHOICE
    if [[ "$DELETE_CHOICE" =~ ^[Yy]$ ]]; then
        qm stop "$TEST_VM_ID"
        qm destroy "$TEST_VM_ID"
        echo "✅ Test VM destroyed."
    else
        echo "⚠️ Test VM $TEST_VM_ID kept running for manual inspection."
    fi

    rm -rf "$BACKUP_DIR"
}

# === Main Control ===

case "$1" in
    backup)
        backup_proxmox
        ;;
    restore)
        if [[ -z "$2" ]]; then
            echo "❗ Usage: $0 restore /path/to/backup.tar.gz"
            exit 1
        fi
        restore_proxmox "$2"
        ;;
    test-restore)
        test_restore
        ;;
    *)
        echo "Usage: $0 {backup|restore /path/to/backup.tar.gz|test-restore}"
        exit 1
        ;;
esac