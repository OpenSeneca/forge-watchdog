#!/bin/bash
# Forge Watchdog - Monitors Forge connectivity and auto-deploys Squad Dashboard
# Version: 1.0.0
# Author: Archimedes (Engineering)
# License: MIT

set -e

# Configuration
FORGE_HOST="forge"
FORGE_IP="100.93.69.117"
SQUAD_DASHBOARD_REPO="/home/exedev/workspace/tools/squad-dashboard"
LOG_FILE="/home/exedev/.openclaw/workspace/tools/forge-watchdog/watchdog.log"
STATE_FILE="/home/exedev/.openclaw/workspace/tools/forge-watchdog/.state"
LOCK_FILE="/home/exedev/.openclaw/workspace/tools/forge-watchdog/.lock"
PING_TIMEOUT=2
SSH_TIMEOUT=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create directories if needed
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$STATE_FILE")"
mkdir -p "$(dirname "$LOCK_FILE")"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    echo "[${timestamp}] [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Check if Forge is reachable
check_ping() {
    ping -c 1 -W "$PING_TIMEOUT" "$FORGE_HOST" &>/dev/null
    return $?
}

# Check if SSH is accessible
check_ssh() {
    ssh -o ConnectTimeout="$SSH_TIMEOUT" -o BatchMode=yes exedev@"$FORGE_HOST" "echo OK" &>/dev/null
    return $?
}

# Get current state
get_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "unknown"
    fi
}

# Set state
set_state() {
    local state="$1"
    echo "$state" > "$STATE_FILE"
    log "STATE" "Forge state changed to: $state"
}

# Deploy Squad Dashboard to Forge
deploy_dashboard() {
    log "DEPLOY" "Starting Squad Dashboard deployment to Forge..."

    if [ ! -d "$SQUAD_DASHBOARD_REPO" ]; then
        log "ERROR" "Squad Dashboard repository not found at $SQUAD_DASHBOARD_REPO"
        return 1
    fi

    # Clone or update the dashboard on Forge
    if ssh -o ConnectTimeout="$SSH_TIMEOUT" exedev@"$FORGE_HOST" "[ -d squad-dashboard ]"; then
        log "DEPLOY" "Updating existing Squad Dashboard on Forge..."
        ssh -o ConnectTimeout="$SSH_TIMEOUT" exedev@"$FORGE_HOST" "cd squad-dashboard && git pull origin main" || {
            log "ERROR" "Failed to update Squad Dashboard"
            return 1
        }
    else
        log "DEPLOY" "Cloning Squad Dashboard to Forge..."
        ssh -o ConnectTimeout="$SSH_TIMEOUT" exedev@"$FORGE_HOST" "git clone https://github.com/OpenSeneca/squad-dashboard.git" || {
            log "ERROR" "Failed to clone Squad Dashboard"
            return 1
        }
    fi

    log "SUCCESS" "Squad Dashboard deployed to Forge successfully"
    return 0
}

# Main check function
check_forge() {
    log "CHECK" "Checking Forge connectivity..."

    # Check ping
    if check_ping; then
        log "CHECK" "Ping OK - Forge is reachable"
    else
        log "WARN" "Ping FAILED - Forge is unreachable"
        set_state "offline"
        return 1
    fi

    # Check SSH
    if check_ssh; then
        log "CHECK" "SSH OK - Authentication successful"
    else
        log "WARN" "SSH FAILED - Authentication failed or SSH not running"
        set_state "ssh-unavailable"
        return 1
    fi

    # If we're here, Forge is online
    local current_state=$(get_state)

    if [ "$current_state" = "online" ]; then
        log "CHECK" "Forge is still online - no action needed"
        return 0
    fi

    # Forge just came online!
    log "ALERT" "Forge is ONLINE! (was $current_state)"
    set_state "online"

    # Auto-deploy dashboard
    if deploy_dashboard; then
        log "SUCCESS" "Forge recovery complete - Squad Dashboard deployed"
    else
        log "ERROR" "Forge recovery incomplete - Dashboard deployment failed"
    fi

    return 0
}

# Watch mode - run continuously
watch_mode() {
    log "WATCH" "Starting watch mode (checking every 60 seconds)"
    log "WATCH" "Press Ctrl+C to stop"

    trap "log 'WATCH' 'Watch mode stopped'; exit 0" INT TERM

    while true; do
        check_forge
        sleep 60
    done
}

# Status command
show_status() {
    local current_state=$(get_state)
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

    echo "=========================================="
    echo "Forge Watchdog Status"
    echo "=========================================="
    echo "Time: $timestamp"
    echo "State: $current_state"
    echo "Forge Host: $FORGE_HOST ($FORGE_IP)"
    echo ""

    if check_ping; then
        echo -e "${GREEN}✓ Ping: OK${NC}"
    else
        echo -e "${RED}✗ Ping: FAILED${NC}"
    fi

    if check_ssh; then
        echo -e "${GREEN}✓ SSH: OK${NC}"
    else
        echo -e "${RED}✗ SSH: FAILED${NC}"
    fi

    echo ""
    echo "Log: $LOG_FILE"
    echo "State: $STATE_FILE"
    echo "=========================================="
}

# Install cron job
install_cron() {
    local script_path=$(realpath "$0")
    local cron_entry="*/15 * * * * $script_path check >> /home/exedev/.openclaw/workspace/tools/forge-watchdog/cron.log 2>&1"

    log "INSTALL" "Installing cron job for Forge Watchdog..."

    # Check if already installed
    if crontab -l 2>/dev/null | grep -q "forge-watchdog"; then
        log "WARN" "Cron job already installed"
        return 0
    fi

    # Add to crontab
    (crontab -l 2>/dev/null; echo "$cron_entry") | crontab -

    log "SUCCESS" "Cron job installed (runs every 15 minutes)"
}

# Main command dispatcher
main() {
    local command="${1:-check}"

    case "$command" in
        check)
            check_forge
            ;;
        status)
            show_status
            ;;
        watch)
            watch_mode
            ;;
        install)
            install_cron
            ;;
        *)
            echo "Usage: $0 {check|status|watch|install}"
            echo ""
            echo "Commands:"
            echo "  check    - Run one-time connectivity check"
            echo "  status   - Show current status"
            echo "  watch    - Run in continuous watch mode"
            echo "  install  - Install cron job for automatic monitoring"
            exit 1
            ;;
    esac
}

main "$@"
