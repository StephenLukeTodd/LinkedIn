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



---
_Files include placeholders to avoid exposing personal/machine-specific paths. See per-folder README files for exact usage examples._

**Azure VM Ansible Cloning Demo**

 - Location: `Azure VM Ansible Cloning Demo/`
 - Purpose: Demonstrates an end-to-end Ansible-driven workflow for cloning / provisioning VMs in Azure and includes helper scripts to prepare the environment and perform cleanup. This directory is a compact example of infrastructure-as-code and automation for cloud VM lifecycle tasks.

Key contents (high level):

 - `ansible/ansible.cfg` — Ansible configuration used by the playbooks in this project.
 - `ansible/arm_ansible_setup.sh` — helper script to bootstrap Azure/Ansible prerequisites (review before running).
 - `ansible/vm_clone_playbook/main_playbook.yml` — the primary playbook for cloning/creating VMs (start here when reviewing the flow).
 - `ansible/vm_clone_playbook/tasks/` — task fragments for disk attachment, network configuration, NIC details, and VM lifecycle management.
 - `ansible/vm_clone_playbook/azure_ansible_helper_suite/` — collection of helper scripts and runbooks used while developing and testing the cloning flow.

Quick reviewer notes / run checklist:

 - This demo requires Azure credentials and `az` CLI access; don't run against production without reviewing the playbook and variables.
 - Recommended read order: `ansible/ansible.cfg` → `ansible/vm_clone_playbook/main_playbook.yml` → `ansible/vm_clone_playbook/tasks/*` → helper scripts in `azure_ansible_helper_suite/`.
 - To run locally for evaluation (example):

```bash
cd "Azure VM Ansible Cloning Demo/ansible"
# Ensure Azure CLI is authenticated: az login
# Review variables and inventory, then run the main playbook
ansible-playbook vm_clone_playbook/main_playbook.yml
```

Skills demonstrated by this subproject: Ansible playbook design, modular task decomposition, Azure CLI/ARM integration, scripting for environment bootstrap and cleanup, and creating reproducible, auditable infrastructure workflows.

If you'd like, I can add a small README inside `Azure VM Ansible Cloning Demo/ansible/` with step-by-step run instructions and a safe dev/test inventory example.

