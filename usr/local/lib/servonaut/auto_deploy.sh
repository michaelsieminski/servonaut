#!/bin/bash

webhook_token=$(cat /home/servonaut/.webhook_token)

# Verify the webhook signature
signature=$(echo -n "$webhook_token$1" | openssl sha1 -hmac "$webhook_token" | sed 's/^.* //')
if [ "$signature" != "$2" ]; then
    echo -e "\n❌ Invalid webhook signature"
    exit 1
fi

# Change to the application directory
cd /var/www/app

# Pull the latest changes from the main branch
sudo -u servonaut git pull origin main

# Install any new dependencies
sudo -u servonaut /root/.bun/bin/bun install

# Build the Nuxt project
sudo -u servonaut /root/.bun/bin/bun run build

# Restart the Nuxt service
systemctl restart nuxt.service

echo -e "\n✅ Deployment completed successfully"
