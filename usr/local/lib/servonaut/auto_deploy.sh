#!/bin/bash
set -e

# Change to the application directory
cd /var/www/app || exit 1

# Execute deployment steps
sudo -u servonaut git pull origin main
sudo -u servonaut /home/servonaut/.bun/bin/bun install
sudo -u servonaut bash -c 'cd /var/www/app && TMPDIR=/tmp/servonaut NODE_OPTIONS="--no-warnings" /home/servonaut/.bun/bin/bun run build'

# Restart the Nuxt service to apply changes
systemctl restart nuxt.service

echo "Deployment completed successfully"
