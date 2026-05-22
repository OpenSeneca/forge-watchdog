# Forge Watchdog

Monitors Forge server connectivity and auto-deploys the Squad Dashboard when it comes back online.

## Problem

Forge server (100.93.69.117) has been offline for 15+ days. The Squad Dashboard v1.0.0 is ready to deploy but requires Forge to be accessible.

## Solution

This tool:
- Monitors Forge connectivity via ping and SSH
- Automatically deploys Squad Dashboard when Forge comes online
- Logs all uptime/downtime events
- Can run as a daemon for continuous monitoring

## Usage

```bash
# Check current status
python3 main.py --check

# Force deployment attempt (if reachable)
python3 main.py --deploy

# Run in watch mode (daemon) - checks every 5 minutes
python3 main.py --watch

# Watch mode with custom interval (e.g., every 60 seconds)
python3 main.py --watch --interval 60
```

## Features

- **Connectivity checking**: Ping and SSH tests
- **Auto-deployment**: Deploys Squad Dashboard when Forge is reachable
- **State persistence**: Remembers last online time and deployment status
- **Event logging**: Logs all events to memory/forge-watchdog-YYYY-MM-DD.log
- **Configurable intervals**: Adjust check frequency as needed

## Deployment

The tool deploys the Squad Dashboard from:
- Source: `/home/exedev/.openclaw/workspace/tools/squad-dashboard/`
- Target: `/var/www/html/dashboard` on Forge

## Requirements

- SSH key deployed to Forge (use `squad-ssh-key-deployer`)
- SSH access to Forge server
- Write permissions on Forge's web directory

## Monitoring

The tool creates a log file at:
```
~/.openclaw/workspace/memory/forge-watchdog-YYYY-MM-DD.log
```

State is persisted in:
```
~/.openclaw/forge-watchdog-state.json
```

## Cron Job

To run continuously as a daemon, use the install script:
```bash
bash install-cron.sh
```

Or manually add to crontab:
```bash
*/5 * * * * cd /home/exedev/.openclaw/workspace/tools/forge-watchdog && /usr/bin/python3 main.py --watch >> /dev/null 2>&1
```

## Status

- Created: 2026-05-18
- Status: Ready for deployment
- Deployed to: OpenSeneca/forge-watchdog (pending)
