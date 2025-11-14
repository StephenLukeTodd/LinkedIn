# Infrastructure & Automation Scripts

This repository is a curated collection of personal automation, backup, and infrastructure helper scripts I build and use for home lab and small-scale server administration. It's organized to make it easy for a recruiter or technical interviewer to scan the candidate's applied skills quickly.

Key skills demonstrated:

- Linux system automation (Bash) — backups, restores, rsync, cron/systemd-friendly scripts
- Proxmox LXC and VM management (backup/restore automation)
- Cloudflare tunneling and API automation
- PowerShell automation for Windows file movement and sync
- Docker usage and deployment automation (installation scripts)
- DevOps-style scripting: logging, error handling, idempotency, and credentials handling

How to read this repo at a glance

- `Backups/` — Proxmox/backup scripts (upload to MEGA, cleanup and restore helpers)
- `Cloudflare_Config/` — helpers for creating and managing Cloudflare tunnel tokens and TLS changes
- `Network Shares/` — network share helper scripts and tests
- `SillyTavern/` — small project deployment scripts for a hobby app (install/uninstall/service)
 - `scripts/` — assorted utilities (bash) such as `HDD_Backup.sh`, `organize_movies.sh`, `openwebui_install.sh`, and `PLEX_MEGA_Setup.sh`
 - `powershell/` — Windows/PowerShell helpers such as `Copy.ps1`, `MovementScript.ps1`, and photo/file movement scripts

If you'd like a guided walkthrough during an interview, open `docs/PROJECT_OVERVIEW.md` for a one-page map of the repository and a suggested talking order.

Contact / Next steps

If you're a recruiter or engineer reviewing this repo and you'd like a short demo or explanation of any script, ping me and I can either walk through it live or provide a short recorded walkthrough for the most relevant scripts.

---
_Files include placeholders to avoid exposing personal/machine-specific paths. See per-folder README files for exact usage examples._

