#!/bin/bash

# Send initial response headers to keep the connection alive
echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r"

# Read the headers
declare -A headers
while IFS=': ' read -r key value; do
    # Remove carriage return from value
    value=${value%$'\r'}
    # Break on empty line
    [ -z "$key" ] && break
    headers["$key"]="$value"
done

# Read the body with content length
content_length="${headers[Content - Length]}"
if [ -n "$content_length" ]; then
    body=$(dd bs=1 count=$content_length 2>/dev/null)
fi

# Get the signature from headers
signature="${headers[X - Hub - Signature]}"
if [[ "$signature" =~ ^sha1=(.*)$ ]]; then
    signature="${BASH_REMATCH[1]}"
fi

webhook_token=$(cat /home/servonaut/.webhook_token)

# Verify the webhook signature
expected_signature=$(echo -n "$body" | openssl sha1 -hmac "$webhook_token" | sed 's/^.* //')
if [ "$signature" != "$expected_signature" ]; then
    echo -e "\n❌ Invalid webhook signature\n"
    exit 1
fi

echo -e "\n🚀 Starting deployment...\n"

# Change to the application directory
cd /var/www/app || exit 1

# Pull the latest changes from the main branch
sudo -u servonaut git pull origin main

# Install any new dependencies
sudo -u servonaut /home/servonaut/.bun/bin/bun install

# Build the Nuxt project
sudo -u servonaut bash -c 'cd /var/www/app && TMPDIR=/tmp/servonaut NODE_OPTIONS="--no-warnings" /home/servonaut/.bun/bin/bun run build || true'

# Restart the Nuxt service
systemctl restart nuxt.service

echo -e "\n✅ Deployment completed successfully\n"
