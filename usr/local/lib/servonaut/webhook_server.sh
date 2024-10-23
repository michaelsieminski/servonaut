#!/bin/bash

# Create Unix socket with proper error handling
exec socat \
    UNIX-LISTEN:/run/webhook/webhook.sock,fork,mode=600,user=servonaut \
    SYSTEM:"/usr/local/lib/servonaut/auto_deploy.sh",nofork
