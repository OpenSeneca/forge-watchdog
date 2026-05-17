# Forge Watchdog Build Log

## Tool: forge-watchdog v1.0.0

### Build Date
2026-05-17 00:33 UTC

### Purpose
Monitors forge server connectivity and auto-deploys Squad Dashboard when forge comes online. Addresses the issue where forge is frequently offline (currently offline 13 days).

### Features Built
1. **check mode**: One-time connectivity check and auto-deploy
2. **daemon mode**: Continuous monitoring with 5-minute intervals
3. **cron mode**: Scheduled checks via cron job
4. **Status tracking**: JSON status file with last check, online time, deploy count
5. **Logging**: Timestamped logs for all operations
6. **Notifications**: Optional email notifications for deployment events

### Files Created
- `README.md` - Documentation
- `forge-watchdog.sh` - Main script (5124 bytes)
- `config.sh` - Configuration (706 bytes)
- `install-cron.sh` - Cron installation script (950 bytes)
- `package.json` - NPM package file (741 bytes)

### Testing
✓ Check mode works correctly
✓ Status tracking functional
✓ Forge correctly detected as offline

### Current Status
- Forge is offline (100.93.69.117)
- Consecutive offline checks: 1
- Deployments: 0

### Next Steps
1. Run `./install-cron.sh` to install as cron job (every 15 minutes)
2. Forge watchdog will automatically deploy dashboard when forge comes online
3. Logs will be written to `forge-watchdog.log`

### Dependencies
- Bash 4+
- SSH client
- jq (for JSON processing)
- Squad Dashboard v2 (for deployment)

### Notes
- Uses SSH timeout of 5 seconds to prevent hanging
- Notifications can be enabled via config.sh
- Logs and status files are stored in the tool directory
