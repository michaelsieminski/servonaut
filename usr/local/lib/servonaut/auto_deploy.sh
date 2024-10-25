#!/bin/bash
set -e

# Set up logging
exec 1> >(logger -s -t $(basename $0)) 2>&1

echo "Starting deployment process..."
cd /var/www/app || {
    echo "Failed to change directory"
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

echo "Building application..."
sudo -u servonaut bash -c 'cd /var/www/app && TMPDIR=/tmp/servonaut NODE_OPTIONS="--no-warnings" /home/servonaut/.bun/bin/bun run build' || {
    echo "Build failed"
    exit 1
}

echo "Restarting Nuxt service..."
systemctl restart nuxt.service || {
    echo "Service restart failed"
    exit 1
}

echo "Deployment completed successfully"
