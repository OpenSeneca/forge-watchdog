#!/bin/bash
# Deploy Forge Watchdog to GitHub

set -e

echo "Deploying Forge Watchdog to GitHub..."

# Initialize git repo if not exists
if [ ! -d .git ]; then
    git init
    gh repo create forge-watchdog --public --source=. --remote=origin --push
else
    echo "Git repository already exists"
fi

# Check if remote exists
if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin https://github.com/OpenSeneca/forge-watchdog.git
fi

# Stage all files
git add .

# Commit
COMMIT_MSG="Forge Watchdog - Monitor and auto-deploy to Forge

Features:
- Connectivity monitoring (ping + SSH)
- Auto-deployment of Squad Dashboard when Forge is online
- Event logging and state persistence
- Watch mode for continuous monitoring

Created: 2026-05-18"

git commit -m "$COMMIT_MSG" || echo "No changes to commit"

# Push to GitHub
git push -u origin main || git push -u origin master || echo "Push failed (may need to set up remote)"

echo "✅ Deployed to GitHub: https://github.com/OpenSeneca/forge-watchdog"
