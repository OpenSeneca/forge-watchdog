# Forge Watchdog

Monitors forge server connectivity and auto-deploys the Squad Dashboard when forge comes online.

## Problem

Forge (100.93.69.117) frequently goes offline. Manual deployment after each outage is tedious. This tool automates deployment when forge recovers.

## Usage

### One-time check
```bash
./forge-watchdog.sh check
```

### Run continuously (daemon mode)
```bash
./forge-watchdog.sh daemon
```

### Install as cron job (runs every 15 minutes)
```bash
./install-cron.sh
```

## How It Works

1. **Check mode**: Tests forge connectivity and deploys if online
2. **Daemon mode**: Runs in background, checks every 5 minutes, deploys when forge comes online
3. **Cron mode**: Scheduled checks via cron

## Features

- SSH connectivity check with timeout
- Auto-deploy of Squad Dashboard v2
- Timestamped logs in `forge-watchdog.log`
- Status tracking (`status.json` remembers last deployment)
- Email notifications (optional, requires `agentmail`)

## Configuration

Edit `config.sh`:

```bash
FORGE_HOST="100.93.69.117"
FORGE_USER="root"
FORGE_DIR="/opt/squad-dashboard-v2"
CHECK_INTERVAL=300  # seconds (5 minutes)
SSH_TIMEOUT=5  # seconds
```

## Requirements

- SSH access to forge via Tailscale
- Squad Dashboard v2 installed at `../squad-dashboard-v2/`
- Bash 4+

## Logs

Logs are written to `forge-watchdog.log` in the same directory. Format:

```
[2026-05-17 00:27:15] INFO: Checking forge connectivity...
[2026-05-17 00:27:15] WARN: Forge is offline (100.93.69.117)
[2026-05-17 00:32:15] INFO: Forge is online! Deploying Squad Dashboard...
[2026-05-17 00:33:20] INFO: Deployment successful
```

## Status Tracking

`status.json` stores:
- `last_check`: timestamp of last check
- `last_online`: timestamp when forge was last seen online
- `last_deploy`: timestamp of last successful deployment
- `deploy_count`: number of deployments performed

## License

MIT
