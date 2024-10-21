#!/bin/bash

setup_caddy() {
    # Ask for the domain name
    read -p "Enter your domain name (e.g., example.com): " domain_name

    # Validate domain name (basic check)
    if [[ ! $domain_name =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo "Invalid domain name. Please enter a valid domain."
        return 1
    fi

    echo "Setting up Caddy..."

    # Download & Install Caddy Web Server
    if ! curl -o caddy.tar.gz -L "https://caddyserver.com/api/download?os=linux&arch=arm64&idempotency=29341600578110"; then
        echo "Failed to download Caddy. Please check your internet connection."
        return 1
    fi

    if ! tar xzf caddy.tar.gz; then
        echo "Failed to extract Caddy. The downloaded file might be corrupted."
        rm caddy.tar.gz
        return 1
    fi

    if [ ! -f caddy ]; then
        echo "Caddy binary not found after extraction."
        rm caddy.tar.gz
        return 1
    fi

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

    systemctl daemon-reload
    systemctl enable caddy.service
    if ! systemctl start caddy.service; then
        echo "Failed to start Caddy service. Check the logs with 'journalctl -u caddy.service'"
        return 1
    fi

    # Configure Caddy as a reverse proxy
    mkdir -p /etc/caddy
    cat > /etc/caddy/Caddyfile << EOF
$domain_name {
    reverse_proxy localhost:3000
}
EOF

    # Reload Caddy to apply the changes
    if ! systemctl reload caddy.service; then
        echo "Failed to reload Caddy service. Check the logs with 'journalctl -u caddy.service'"
        return 1
    fi

    echo "Caddy setup completed successfully."
}
