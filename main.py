#!/usr/bin/env python3
"""
Forge Watchdog - Monitors Forge connectivity and auto-deploys when online

Monitors the Forge server (100.93.69.117) and automatically deploys the Squad
Dashboard v2.1.0 when it comes back online after being offline.

Features:
- Periodic connectivity checks via ping and SSH
- Auto-deployment of Squad Dashboard when Forge is reachable
- Logging of uptime/downtime events
- Configurable check intervals

Usage:
    python3 main.py --check          # Check current status
    python3 main.py --deploy          # Deploy dashboard (if reachable)
    python3 main.py --watch          # Run in watch mode (daemon)
    python3 main.py --deploy-dashboard # Force deployment attempt
"""

import subprocess
import time
import json
from pathlib import Path
from datetime import datetime
from typing import Dict, Optional

# Forge configuration
FORGE_HOST = "100.93.69.117"
FORGE_USER = "root"
FORGE_SSH_PORT = 22

# Dashboard deployment paths
DASHBOARD_DIR = "/home/exedev/.openclaw/workspace/tools/squad-dashboard"
DEPLOY_PATH = "/var/www/html/dashboard"

# State file
STATE_FILE = Path.home() / ".openclaw" / "forge-watchdog-state.json"

# Log file
LOG_FILE = Path.home() / ".openclaw" / "workspace" / "memory" / f"forge-watchdog-{datetime.now().strftime('%Y-%m-%d')}.log"

def run_command(cmd: list, timeout: int = 10) -> tuple[int, str, str]:
    """Run command with timeout, return (exit_code, stdout, stderr)."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "Command timed out"
    except Exception as e:
        return -1, "", str(e)

def ping_forge() -> bool:
    """Ping Forge server to check connectivity."""
    result = run_command(["ping", "-c", "1", "-W", "2", FORGE_HOST], timeout=5)
    return result[0] == 0

def check_ssh_connectivity() -> bool:
    """Check if SSH connection to Forge is possible."""
    result = run_command(
        ["ssh", "-o", "ConnectTimeout=5", "-o", "BatchMode=yes",
         f"{FORGE_USER}@{FORGE_HOST}", "echo 'SSH OK'"],
        timeout=10
    )
    return result[0] == 0

def get_status() -> Dict:
    """Get current Forge status."""
    ping_ok = ping_forge()
    ssh_ok = check_ssh_connectivity() if ping_ok else False

    return {
        "host": FORGE_HOST,
        "ping": ping_ok,
        "ssh": ssh_ok,
        "timestamp": datetime.now().isoformat()
    }

def load_state() -> Dict:
    """Load watchdog state from file."""
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except:
            return {}
    return {}

def save_state(state: Dict):
    """Save watchdog state to file."""
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2))

def log_event(message: str):
    """Log an event to the log file."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_line = f"[{timestamp}] {message}\n"
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(log_line)
    print(log_line.strip())

def deploy_dashboard() -> bool:
    """Deploy Squad Dashboard v2.1.0 to Forge."""
    log_event("Starting Squad Dashboard deployment to Forge...")

    # Check if dashboard directory exists
    dashboard_path = Path(DASHBOARD_DIR)
    if not dashboard_path.exists():
        log_event(f"ERROR: Dashboard directory not found: {DASHBOARD_DIR}")
        return False

    # Create deployment archive
    log_event("Creating deployment archive...")
    archive_result = run_command(
        ["tar", "-czf", "/tmp/dashboard.tar.gz", "-C", str(dashboard_path), "."],
        timeout=30
    )
    if archive_result[0] != 0:
        log_event(f"ERROR: Failed to create archive: {archive_result[2]}")
        return False

    # Upload to Forge
    log_event("Uploading to Forge...")
    upload_result = run_command(
        ["scp", "-o", "ConnectTimeout=30", "-o", "BatchMode=yes",
         "/tmp/dashboard.tar.gz", f"{FORGE_USER}@{FORGE_HOST}:/tmp/"],
        timeout=60
    )
    if upload_result[0] != 0:
        log_event(f"ERROR: Upload failed: {upload_result[2]}")
        return False

    # Extract and deploy
    log_event("Extracting and deploying on Forge...")
    deploy_commands = [
        f"mkdir -p {DEPLOY_PATH}",
        f"tar -xzf /tmp/dashboard.tar.gz -C {DEPLOY_PATH}",
        "rm /tmp/dashboard.tar.gz",
        f"chown -R www-data:www-data {DEPLOY_PATH}",
        "systemctl reload nginx 2>/dev/null || true"
    ]

    for cmd in deploy_commands:
        ssh_result = run_command(
            ["ssh", "-o", "BatchMode=yes", f"{FORGE_USER}@{FORGE_HOST}", cmd],
            timeout=30
        )
        if ssh_result[0] != 0:
            log_event(f"ERROR: Deploy command failed: {cmd} - {ssh_result[2]}")
            return False

    log_event("✅ Squad Dashboard deployed successfully to Forge")
    return True

def watch_mode(interval: int = 300):
    """Run in watch mode, checking connectivity periodically."""
    log_event("Forge Watchdog started in watch mode")
    log_event(f"Check interval: {interval} seconds")

    state = load_state()
    last_online = state.get("last_online")
    deployed = state.get("deployed", False)

    while True:
        status = get_status()

        print(f"\n[{status['timestamp']}] Forge Status:")
        print(f"  Ping: {'✓' if status['ping'] else '✗'}")
        print(f"  SSH:  {'✓' if status['ssh'] else '✗'}")

        if status['ping'] and status['ssh']:
            log_event("Forge is ONLINE and SSH accessible")
            state["last_online"] = status['timestamp']

            # Deploy if not already deployed
            if not deployed:
                log_event("Forge came online - attempting dashboard deployment...")
                if deploy_dashboard():
                    deployed = True
                    state["deployed"] = True
                    state["deployed_at"] = datetime.now().isoformat()
                    save_state(state)
            else:
                log_event("Forge is online - dashboard already deployed")
        else:
            log_event("Forge is OFFLINE or unreachable")
            if status['ping']:
                log_event("  Ping OK but SSH not accessible")
            else:
                log_event("  Ping failed")

        save_state(state)
        time.sleep(interval)

def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Forge Watchdog - Monitor and auto-deploy to Forge"
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check current Forge status"
    )
    parser.add_argument(
        "--deploy",
        action="store_true",
        help="Deploy dashboard if reachable"
    )
    parser.add_argument(
        "--watch",
        action="store_true",
        help="Run in watch mode (daemon)"
    )
    parser.add_argument(
        "--interval",
        type=int,
        default=300,
        help="Check interval in seconds for watch mode (default: 300)"
    )

    args = parser.parse_args()

    # Default to check if no action specified
    if not any([args.check, args.deploy, args.watch]):
        args.check = True

    if args.check:
        print("Forge Connectivity Check")
        print("=" * 60)
        status = get_status()
        print(f"Host: {status['host']}")
        print(f"Ping: {'✓ OK' if status['ping'] else '✗ FAILED'}")
        print(f"SSH:  {'✓ OK' if status['ssh'] else '✗ FAILED'}")
        print(f"Time: {status['timestamp']}")

        state = load_state()
        if state.get("last_online"):
            print(f"\nLast online: {state['last_online']}")
        if state.get("deployed"):
            print(f"Dashboard deployed at: {state.get('deployed_at')}")

        sys.exit(0 if status['ssh'] else 1)

    if args.deploy:
        status = get_status()
        if not status['ssh']:
            print("✗ Forge is not SSH accessible. Cannot deploy.")
            sys.exit(1)

        print("Deploying Squad Dashboard to Forge...")
        success = deploy_dashboard()
        sys.exit(0 if success else 1)

    if args.watch:
        watch_mode(args.interval)

if __name__ == "__main__":
    import sys
    main()
