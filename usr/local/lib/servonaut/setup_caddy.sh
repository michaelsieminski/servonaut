#!/bin/bash

setup_caddy() {
    echo -e "\n🛠️  Setting up Caddy...\n"
    sleep 1

    domain_name=$(cat /home/servonaut/.domain_name)

    # Check and remove existing Caddy binary
    if [ -f "/usr/local/bin/caddy" ]; then
        echo -e "🗑️  Removing existing Caddy binary...\n"
        rm -f /usr/local/bin/caddy
    fi

    # Download Caddy binary directly
    if ! curl -o /usr/local/bin/caddy -L "https://caddyserver.com/api/download?os=linux&arch=arm64"; then
        echo -e "\nFailed to download Caddy. Please check your internet connection."
        exit 1
    fi

    # Make Caddy executable
    chmod +x /usr/local/bin/caddy

    # Setup Caddy as a service
    cat >/etc/systemd/system/caddy.service <<EOF
[Unit]
Description=Caddy Web Server
After=network.target

[Service]
User=servonaut
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
        echo -e "\nFailed to start Caddy service. Check the logs with 'journalctl -u caddy.service'"
        return 1
    fi

    # Configure Caddy
    mkdir -p /etc/caddy
    cat >/etc/caddy/Caddyfile <<EOF
$domain_name {
    root * /var/www/app/.output/public
    encode gzip
    file_server

    handle /hooks/* {
        reverse_proxy localhost:9000
    }

    handle /* {
        reverse_proxy localhost:3000
    }
}
EOF

    chown -R servonaut:servonaut /etc/caddy
    chmod 755 /etc/caddy
    chmod 644 /etc/caddy/Caddyfile

    # Reload Caddy to apply the changes
    if ! systemctl reload caddy.service; then
        echo -e "\n Failed to reload Caddy service. Check the logs with 'journalctl -u caddy.service'"
        return 1
    fi

    echo -e "\n✅ Caddy Server is now set up."
    return 0
}
