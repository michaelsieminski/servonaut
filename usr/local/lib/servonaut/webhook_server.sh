#!/bin/bash

# Create Unix socket with proper error handling
cd /usr/local/lib/servonaut || exit 1

exec socat \
    UNIX-LISTEN:/run/webhook/webhook.sock,fork,mode=660,user=servonaut,reuseaddr \
    EXEC:"/usr/local/lib/servonaut/auto_deploy.sh",nofork
