# Repository Structure (short map)

This file maps important files and folders for quick scanning.

- `README.md` — recruiter-friendly top-level summary and list of skills.
- `docs/PROJECT_OVERVIEW.md` — suggested talking order and quick notes for interviews.

Folders:

- `Backups/` — Proxmox backup/restore automation and MEGA upload utilities. (Look at `container_mega_backup.sh` and `container_restore.sh` first.)
- `Cloudflare_Config/` — cloudflared token insertion and TLS/tunnel change helpers.
- `Network Shares/` — mount/cleanup/test scripts for network shares.
- `SillyTavern/` — hobby app installer/uninstaller and systemd service file.

- Notable script folders:

- `scripts/` — shell utilities (moved from top-level). Notable files include `HDD_Backup.sh`, `openwebui_install.sh`, `organize_movies.sh`, `MoveAnime.sh`, and `PLEX_MEGA_Setup.sh`.
- `powershell/` — Windows automation helpers; notable files include `Copy.ps1`, `MovementScript.ps1`, `Movephotos.ps1`, `Moving_Anime.ps1`, and `SortPhotos.ps1`.

Skills & technologies demonstrated:

- Bash, POSIX shell features, `set -euo pipefail`, error traps
- Proxmox tools (`pct`, `vzdump`) and restore patterns
- Cloudflare API usage (`curl`, `jq`), token management
- MEGAcmd integration for cloud uploads
- Docker and systemd service automation
- PowerShell scripting for Windows automation
