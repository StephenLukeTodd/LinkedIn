# Backups — Proxmox Backup & Restore

Folder: `Backups/`

This folder contains scripts for creating, uploading, cleaning, and restoring Proxmox LXC/VM backups. The scripts are intended to be run on a Proxmox host and are written for reliability and non-interactive operation (cron/systemd).

Main files:

- `container_mega_backup.sh` — primary backup script. Creates snapshots/backups for containers, uploads to MEGA (using MEGAcmd), writes a CSV log, and keeps an upload log. Designed for cron/systemd usage; logs to `/var/log/container_mega_backup.log`.
- `container_mega_backup_clean.sh` — helper to remove old `.tar.zst`, `.csv`, and `.log` files from the backup directory.
- `container_restore.sh` — prompts for MEGA credentials to download backups and performs restores, finds next free VMID if the original exists, tags and starts restored containers, and writes a restore log.
- `proxmox_backup_restore_test.sh` — one-file utility to create a tarball of key Proxmox host config and optionally test a restore in a temporary environment.

Usage notes for reviewers:

- The backup script uses `vzdump`/`pct` and `megacmd` tools — it verifies existence of commands and attempts to install/prepare MEGA client if absent.
- There are CSV logs and human-readable upload logs to help with auditing.
- Sensitive operations (login tokens, remote paths) are read interactively or via env/placeholders — be careful when running on production systems.

Suggested talking points:

- Error handling and `set -Eeuo pipefail` usage.
- Logging approaches for cron-friendly scripts.
- Design of idempotency (checking existing files, dry-run flag patterns).
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