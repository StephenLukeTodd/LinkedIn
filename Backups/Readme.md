# Proxmox VE Backup & Restore Script

A comprehensive Bash script to backup, restore, upload, and test Proxmox VE configurations and virtual machines.

## 📋 Features

- Backup installed packages and configurations.
- Restore configurations and packages on a new Proxmox VE installation.
- Upload backup archives to remote storage.
- Test restoration by creating a temporary VM from the backup.

## 📦 Installation

1. Clone the repository:

   git clone https://github.com/yourusername/proxmox-backup-restore.git
   cd proxmox-backup-restore

   ./proxmox_backup_restore_test.sh backup
   ./proxmox_backup_restore_test.sh restore /path/to/backup.tar.gz
   ./proxmox_backup_restore_test.sh test-restore