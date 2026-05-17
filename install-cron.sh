#!/bin/bash

# Install Forge Watchdog as a cron job

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WATCHDOG_SCRIPT="$SCRIPT_DIR/forge-watchdog.sh"
CRON_INTERVAL=${1:-"*/15 * * * *"}  # Default: every 15 minutes

echo "Installing Forge Watchdog cron job..."
echo "Interval: $CRON_INTERVAL"
echo "Script: $WATCHDOG_SCRIPT"
echo ""

# Check if script exists
if [[ ! -f "$WATCHDOG_SCRIPT" ]]; then
  echo "Error: forge-watchdog.sh not found in $SCRIPT_DIR"
  exit 1
fi

# Add cron job
(crontab -l 2>/dev/null | grep -v "forge-watchdog"; echo "$CRON_INTERVAL $WATCHDOG_SCRIPT check >> $SCRIPT_DIR/cron.log 2>&1") | crontab -

echo "✓ Cron job installed"
echo ""
echo "Crontab entry:"
crontab -l | grep "forge-watchdog"
echo ""
echo "Logs:"
echo "  Watchdog: $SCRIPT_DIR/forge-watchdog.log"
echo "  Cron: $SCRIPT_DIR/cron.log"
echo ""
echo "To remove cron job:"
echo "  crontab -e"
echo "  Delete the line containing 'forge-watchdog'"
