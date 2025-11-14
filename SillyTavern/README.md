# SillyTavern

Folder: `SillyTavern/`

This directory contains helper scripts for installing, uninstalling, and running a small hobby web app called SillyTavern.

Files:

- `sillytavern_install.sh` — installer script to set up dependencies and configuration.
- `sillytavern_uninstall.sh` — removes installed files and services related to SillyTavern.
- `sillytavern.service` — systemd service unit for auto-starting the app.
- `config.yaml` — example configuration for the application.
- `SillyTavern.ps1` — Windows helper script (PowerShell) for related tasks.

Suggested talking points:

- Demonstrates cross-platform deployment and packaging (systemd + Windows helper script).
- Use of service units to make hobby projects production-friendly on a home lab.
