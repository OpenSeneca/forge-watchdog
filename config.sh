#!/bin/bash

# Configuration for Forge Watchdog

# Forge server details
FORGE_HOST="100.93.69.117"
FORGE_USER="root"
FORGE_DIR="/opt/squad-dashboard-v2"
SERVICE_NAME="squad-dashboard-v2"

# Check interval for daemon mode (in seconds)
CHECK_INTERVAL=300  # 5 minutes

# SSH connection timeout (in seconds)
SSH_TIMEOUT=5

# Dashboard location (relative to this script)
DASHBOARD_DIR="../squad-dashboard-v2"

# Log file (relative to script location)
LOG_FILE="forge-watchdog.log"

# Status file (relative to script location)
STATUS_FILE="status.json"

# Enable notifications (set to "true" to enable)
ENABLE_NOTIFICATIONS="false"

# Notification command (e.g., agentmail or mail)
NOTIFICATION_CMD="agentmail"
