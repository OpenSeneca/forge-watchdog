#!/bin/bash

# Forge Watchdog - Monitors forge connectivity and auto-deploys Squad Dashboard

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
if [[ -f "$SCRIPT_DIR/config.sh" ]]; then
  source "$SCRIPT_DIR/config.sh"
else
  echo "Error: config.sh not found in $SCRIPT_DIR"
  exit 1
fi

# Full paths
LOG_FILE="$SCRIPT_DIR/$LOG_FILE"
STATUS_FILE="$SCRIPT_DIR/$STATUS_FILE"
DASHBOARD_DIR="$SCRIPT_DIR/$DASHBOARD_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
  local level="$1"
  shift
  local message="$@"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Send notification
notify() {
  local subject="$1"
  local body="$2"

  if [[ "$ENABLE_NOTIFICATIONS" == "true" ]]; then
    if command -v "$NOTIFICATION_CMD" &> /dev/null; then
      echo "$body" | $NOTIFICATION_CMD -s "$subject"
      log "INFO" "Notification sent: $subject"
    else
      log "WARN" "Notification command not found: $NOTIFICATION_CMD"
    fi
  fi
}

# Update status file
update_status() {
  local key="$1"
  local value="$2"

  if [[ -f "$STATUS_FILE" ]]; then
    # Update existing status
    jq -e ".$key = \"$value\"" "$STATUS_FILE" > "$STATUS_FILE.tmp" 2>/dev/null || echo "{\"$key\":\"$value\"}" > "$STATUS_FILE.tmp"
  else
    # Create new status
    echo "{\"$key\":\"$value\"}" > "$STATUS_FILE.tmp"
  fi

  mv "$STATUS_FILE.tmp" "$STATUS_FILE"
}

# Initialize status file
init_status() {
  if [[ ! -f "$STATUS_FILE" ]]; then
    cat > "$STATUS_FILE" << EOF
{
  "last_check": "never",
  "last_online": "never",
  "last_deploy": "never",
  "deploy_count": 0,
  "consecutive_offline": 0
}
EOF
  fi
}

# Check forge connectivity
check_forge() {
  log "INFO" "Checking forge connectivity to $FORGE_HOST..."

  if ssh -o ConnectTimeout=$SSH_TIMEOUT -o StrictHostKeyChecking=no \
      -o BatchMode=yes \
      ${FORGE_USER}@${FORGE_HOST} "echo 'Forge is accessible'" 2>/dev/null; then
    update_status "last_online" "$(date -Iseconds)"
    return 0
  else
    return 1
  fi
}

# Deploy Squad Dashboard
deploy_dashboard() {
  log "INFO" "Deploying Squad Dashboard to forge..."

  if [[ ! -d "$DASHBOARD_DIR" ]]; then
    log "ERROR" "Dashboard directory not found: $DASHBOARD_DIR"
    return 1
  fi

  cd "$DASHBOARD_DIR"

  # Check if deploy script exists
  if [[ ! -f "deploy-to-forge.sh" ]]; then
    log "ERROR" "deploy-to-forge.sh not found in $DASHBOARD_DIR"
    return 1
  fi

  # Run deployment
  if ./deploy-to-forge.sh > "$SCRIPT_DIR/deploy.log" 2>&1; then
    log "INFO" "Deployment successful"
    update_status "last_deploy" "$(date -Iseconds)"

    # Increment deploy count
    local count=$(jq -r '.deploy_count // 0' "$STATUS_FILE")
    update_status "deploy_count" $((count + 1))

    # Reset consecutive offline counter
    update_status "consecutive_offline" "0"

    notify "✅ Forge Watchdog: Dashboard Deployed" \
      "Squad Dashboard v2 has been successfully deployed to forge ($FORGE_HOST)."

    return 0
  else
    log "ERROR" "Deployment failed. Check $SCRIPT_DIR/deploy.log for details."
    notify "❌ Forge Watchdog: Deployment Failed" \
      "Failed to deploy Squad Dashboard to forge. Check $SCRIPT_DIR/deploy.log for details."
    return 1
  fi
}

# Check mode
check_mode() {
  init_status
  update_status "last_check" "$(date -Iseconds)"

  if check_forge; then
    log "INFO" "✓ Forge is online"
    echo -e "${GREEN}✓ Forge is online${NC}"

    # Check if we should deploy (optional: check if dashboard needs update)
    deploy_dashboard
  else
    log "WARN" "✗ Forge is offline"
    echo -e "${RED}✗ Forge is offline${NC}"

    local count=$(jq -r '.consecutive_offline // 0' "$STATUS_FILE")
    update_status "consecutive_offline" $((count + 1))

    # Only notify on every 10th consecutive offline check (to avoid spam)
    if (( count > 0 && count % 10 == 0 )); then
      notify "⚠️ Forge Watchdog: Forge Still Offline" \
        "Forge has been offline for $((count * CHECK_INTERVAL / 60)) minutes."
    fi
  fi
}

# Daemon mode
daemon_mode() {
  log "INFO" "Starting daemon mode (check interval: ${CHECK_INTERVAL}s)"
  echo -e "${GREEN}Starting daemon mode...${NC}"
  echo "Check interval: ${CHECK_INTERVAL}s"
  echo "Log file: $LOG_FILE"
  echo "Status file: $STATUS_FILE"
  echo ""
  echo "Press Ctrl+C to stop"
  echo ""

  while true; do
    check_mode

    log "INFO" "Next check in ${CHECK_INTERVAL}s..."
    echo -e "\n${YELLOW}Next check in ${CHECK_INTERVAL}s...${NC}"

    sleep $CHECK_INTERVAL
  done
}

# Main entry point
case "${1:-check}" in
  check)
    check_mode
    ;;
  daemon)
    daemon_mode
    ;;
  status)
    init_status
    cat "$STATUS_FILE" | jq '.'
    ;;
  *)
    cat << EOF
Usage: $0 {check|daemon|status}

Commands:
  check    - Check forge connectivity and deploy if online (one-time)
  daemon   - Run continuously, checking every ${CHECK_INTERVAL}s
  status   - Show current status

Configuration: config.sh
Logs: $LOG_FILE
EOF
    exit 1
    ;;
esac
