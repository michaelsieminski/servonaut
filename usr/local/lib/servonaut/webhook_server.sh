#!/bin/bash

# Ensure the socket directory exists with proper permissions
mkdir -p /run/webhook
chown servonaut:servonaut /run/webhook
chmod 755 /run/webhook

# Create Unix socket
socat UNIX-LISTEN:/run/webhook.sock,fork,mode=600,user=servonaut EXEC:/usr/local/lib/servonaut/auto_deploy.sh
