#!/bin/bash
set -e

# Set up logging
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting deployment process..."
cd /var/www/app || {
    echo "Failed to change directory"
    exit 1
}

echo "Resetting local changes..."
sudo -u servonaut git reset --hard HEAD || {
    echo "Git reset failed"
    exit 1
}

echo "Pulling latest changes..."
sudo -u servonaut git pull origin main || {
    echo "Git pull failed"
    exit 1
}

echo "Installing dependencies..."
sudo -u servonaut /home/servonaut/.bun/bin/bun install || {
    echo "Bun install failed"
    exit 1
}

sudo -u servonaut bash -c 'cd /var/www/app && \
        export PATH="/home/servonaut/.bun/bin:$PATH" && \
        export BUN_INSTALL="/home/servonaut/.bun" && \
        TMPDIR=/tmp/servonaut NODE_OPTIONS="--no-warnings" /home/servonaut/.bun/bin/bun run build || true'

echo "Restarting application service..."
sudo systemctl restart app.service || {
    echo "App service restart failed"
    exit 1
}

echo "Deployment completed successfully"
