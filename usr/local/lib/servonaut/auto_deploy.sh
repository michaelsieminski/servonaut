#!/bin/bash

# Read the webhook payload from stdin
read -r request_line
while IFS='' read -r header_line && [ -n "$header_line" ]; do
    if [[ "$header_line" =~ ^X-Hub-Signature:\ sha1=(.*)$ ]]; then
        signature="${BASH_REMATCH[1]}"
    fi
done

# Read the body
body=$(cat)

webhook_token=$(cat /home/servonaut/.webhook_token)

# Verify the webhook signature
expected_signature=$(echo -n "$body" | openssl sha1 -hmac "$webhook_token" | sed 's/^.* //')
if [ "$signature" != "$expected_signature" ]; then
    echo -e "HTTP/1.1 403 Forbidden\r\nContent-Type: text/plain\r\n\r\nInvalid webhook signature"
    exit 1
fi

# Send HTTP response headers early
echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\nStarting deployment..."

# Change to the application directory
cd /var/www/app

# Pull the latest changes from the main branch
sudo -u servonaut git pull origin main

# Install any new dependencies
sudo -u servonaut /home/servonaut/.bun/bin/bun install

# Build the Nuxt project
sudo -u servonaut bash -c 'cd /var/www/app && TMPDIR=/tmp/servonaut NODE_OPTIONS="--no-warnings" /home/servonaut/.bun/bin/bun run build || true'

# Restart the Nuxt service
systemctl restart nuxt.service

echo "Deployment completed successfully"
