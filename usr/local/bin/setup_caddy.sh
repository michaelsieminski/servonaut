#!/bin/bash

setup_caddy() {
    # Download & Install Caddy Web Server
    curl -o caddy.tar.gz -L "https://caddyserver.com/api/download?os=linux&arch=arm64&idempotency=29341600578110"
    tar xzf caddy.tar.gz
    mv caddy /usr/local/bin/
    rm caddy.tar.gz

    # Setup Caddy as a service
    cat > /etc/systemd/system/caddy.service << EOF
[Unit]
Description=Caddy Web Server
After=network.target

[Service]
ExecStart=/usr/local/bin/caddy run --config /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --config /etc/caddy/Caddyfile
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable caddy.service
    systemctl start caddy.service

    # Configure Caddy as a reverse proxy
    mkdir -p /etc/caddy
    cat > /etc/caddy/Caddyfile << EOF
your-domain.com {
    reverse_proxy localhost:3000
}
EOF

    # Reload Caddy to apply the changes
    systemctl reload caddy.service
}