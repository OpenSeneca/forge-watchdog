# Forge Watchdog

Monitors Forge connectivity and automatically deploys Squad Dashboard when Forge comes back online.

## Problem Solved

Forge has been offline for 15+ days due to network/host issues. Manual monitoring and deployment is time-consuming. Forge Watchdog automates the recovery process.

## Features

- **Ping monitoring** - Checks if Forge host is reachable
- **SSH monitoring** - Verifies SSH authentication is working
- **State tracking** - Remembers Forge's last state (online/offline)
- **Auto-deployment** - Deploys Squad Dashboard when Forge recovers
- **Event logging** - Logs all events with timestamps
- **Watch mode** - Continuous monitoring daemon
- **Cron integration** - Scheduled checks every 15 minutes

## Installation

```bash
cd ~/.openclaw/workspace/tools/forge-watchdog
./forge-watchdog.sh install
```

This adds a cron job that runs every 15 minutes.

## Usage

```bash
# One-time check
./forge-watchdog.sh check

# Show current status
./forge-watchdog.sh status

# Run in continuous watch mode (daemon)
./forge-watchdog.sh watch

# Install/verify cron job
./forge-watchdog.sh install
```

## How It Works

1. **Check Phase** - Runs ping and SSH tests to Forge
2. **State Comparison** - Compares current state with last known state
3. **Recovery Detection** - If Forge was offline and is now online:
   - Logs recovery event
   - Deploys Squad Dashboard via git clone/pull
4. **State Update** - Saves current state for next check

## State Machine

```
unknown ──► offline ──► online ◄────┐
   │           │          │       │
   └───────────┴──────────┴───────┘
```

## Files

- `forge-watchdog.sh` - Main script
- `watchdog.log` - Event log with timestamps
- `.state` - Current Forge state (offline/online)
- `cron.log` - Cron execution log
- `.lock` - Prevents multiple instances

## Dashboard Deployment

When Forge comes online, the watchdog:

1. Checks if `squad-dashboard` exists on Forge
2. If yes: Runs `git pull origin main`
3. If no: Clones from `https://github.com/OpenSeneca/squad-dashboard.git`

## Requirements

- SSH access to Forge (exedev@forge)
- Git access to OpenSeneca GitHub repo
- Bash shell

## Monitoring

```bash
# Watch logs in real-time
tail -f ~/.openclaw/workspace/tools/forge-watchdog/watchdog.log

# Check cron execution logs
tail -f ~/.openclaw/workspace/tools/forge-watchdog/cron.log

# View current state
cat ~/.openclaw/workspace/tools/forge-watchdog/.state
```

## Troubleshooting

**Issue: Watchdog always reports offline**
- Check network connectivity: `ping forge`
- Verify SSH access: `ssh exedev@forge echo test`

**Issue: Dashboard deployment fails**
- Check GitHub repo exists and is accessible
- Verify Forge has git installed: `ssh exedev@forge "git --version"`
- Check watchdog.log for detailed error messages

**Issue: Cron job not running**
- Verify crontab entry: `crontab -l | grep forge-watchdog`
- Check cron logs: `tail -f ~/.openclaw/workspace/tools/forge-watchdog/cron.log`

## Version History

- **1.0.0** - Initial release with ping/SSH monitoring, state tracking, auto-deployment

## License

MIT

## Author

Archimedes (Engineering) - OpenSeneca Squad
