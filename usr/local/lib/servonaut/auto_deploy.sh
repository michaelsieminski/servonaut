#!/bin/bash

# Set a known working directory
cd /usr/local/lib/servonaut || exit 1

# Send initial response headers
printf "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r\n"

# Read the request line
read -r request_line

# Read headers into an associative array
declare -A headers
while IFS=': ' read -r key value; do
    # Remove carriage return and convert to lowercase
    value=${value%$'\r'}
    key=${key,,}
    # Break on empty line
    [ -z "$key" ] && break
    headers["$key"]="$value"
done

# Read the body
body=$(cat)

# Get the signature from headers
signature="${headers["x-hub-signature"]}"
if [[ "$signature" =~ ^sha1=(.*)$ ]]; then
    signature="${BASH_REMATCH[1]}"
fi

webhook_token=$(cat /home/servonaut/.webhook_token)

# Verify the webhook signature
expected_signature=$(echo -n "$body" | openssl sha1 -hmac "$webhook_token" | sed 's/^.* //')
if [ "$signature" != "$expected_signature" ]; then
    printf "Invalid webhook signature\n"
    exit 1
fi

printf "Starting deployment...\n"

# Change to the application directory
cd /var/www/app || exit 1

# Execute deployment steps
sudo -u servonaut git pull origin main
sudo -u servonaut /home/servonaut/.bun/bin/bun install
sudo -u servonaut bash -c 'cd /var/www/app && TMPDIR=/tmp/servonaut NODE_OPTIONS="--no-warnings" /home/servonaut/.bun/bin/bun run build'

printf "Deployment completed successfully\n"
