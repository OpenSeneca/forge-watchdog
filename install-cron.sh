#!/bin/bash
# Install Forge Watchdog as a cron job

set -e

WATCHDOG_DIR="/home/exedev/.openclaw/workspace/tools/forge-watchdog"
CRON_ENTRY="*/5 * * * * cd $WATCHDOG_DIR && /usr/bin/python3 main.py --watch >> /dev/null 2>&1"

echo "Installing Forge Watchdog as a cron job..."
echo ""

# Check if watchdog directory exists
if [ ! -d "$WATCHDOG_DIR" ]; then
    echo "ERROR: Forge Watchdog directory not found: $WATCHDOG_DIR"
    exit 1
fi

# Check if cron entry already exists
if crontab -l 2>/dev/null | grep -q "forge-watchdog"; then
    echo "Forge Watchdog cron entry already exists."
    echo ""
    echo "Current cron entry:"
    crontab -l 2>/dev/null | grep "forge-watchdog"
    echo ""
    read -p "Replace existing entry? (y/N): " replace
    if [ "$replace" != "y" ]; then
        echo "Installation cancelled."
        exit 0
    fi

    # Remove existing entry
    crontab -l 2>/dev/null | grep -v "forge-watchdog" | crontab -
fi

# Add new cron entry
(crontab -l 2>/dev/null; echo "$CRON_ENTRY") | crontab -

echo "✅ Forge Watchdog installed as cron job"
echo ""
echo "Cron entry:"
echo "  $CRON_ENTRY"
echo ""
echo "The watchdog will now run every 5 minutes."
echo "Logs are stored in: ~/.openclaw/workspace/memory/forge-watchdog-YYYY-MM-DD.log"
echo ""
echo "To view logs:"
echo "  tail -f ~/.openclaw/workspace/memory/forge-watchdog-$(date +%Y-%m-%d).log"
echo ""
echo "To stop the watchdog, edit crontab:"
echo "  crontab -e"
echo "  # Remove the forge-watchdog line"
