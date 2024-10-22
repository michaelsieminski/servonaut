#!/bin/bash

setup_caddy() {
    echo -e "📝 Domain Configuration\n"

    while true; do
        read -p "Enter your domain name (e.g., example.com): " domain_name
        echo ""

        if [[ ! $domain_name =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo -e "\n❌ Invalid domain name. Please enter a valid domain.\n"
            continue
        fi

        server_ip=$(get_server_ip)

        echo -e "Please create the following A record for your domain:\n"
        printf "┌───────┬──────┬────────────────────────────┐\n"
        printf "│ %-5s │ %-4s │ %-26s │\n" "Host" "Type" "Value"
        printf "├───────┼──────┼────────────────────────────┤\n"
        printf "│ %-5s │ %-4s │ %-26s │\n" "@" "A" "$server_ip"
        printf "└───────┴──────┴────────────────────────────┘\n"

        read -p "Have you added this A record? (yes/no): " dns_confirmation
        echo ""

        if [[ $dns_confirmation =~ ^[Yy][Ee]?[Ss]?$ ]]; then
            echo -e "🔍 Checking DNS propagation... This may take a moment.\n"
            sleep 2
            if check_dns "$domain_name" "$server_ip"; then
                echo -e "\n✅ DNS record verified successfully."
                break
            else
                echo -e "\n⚠️  The domain does not yet point to the correct IP address."
                echo -e "   This could be due to DNS propagation delay.\n"
                echo -e "   Options:"
                echo -e "   1. Wait and try again (recommended)"
                echo -e "   2. Continue anyway (may cause issues with HTTPS setup)\n"
                read -p "Do you want to continue anyway? (yes/no): " continue_anyway
                echo ""
                if [[ $continue_anyway =~ ^[Yy][Ee]?[Ss]?$ ]]; then
                    break
                fi
            fi
        else
            echo -e "\nPlease add the A record before continuing.\n"
        fi
    done

    echo -e "\n🛠️  Setting up Caddy...\n"
    sleep 1

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

    # Configure Caddy as a reverse proxy
    mkdir -p /etc/caddy
    cat >/etc/caddy/Caddyfile <<EOF
$domain_name {
    reverse_proxy localhost:3000
}
EOF

    # Reload Caddy to apply the changes
    if ! systemctl reload caddy.service; then
        echo -e "\n Failed to reload Caddy service. Check the logs with 'journalctl -u caddy.service'"
        return 1
    fi

    echo -e "\n✅ Caddy Server is now set up."
    sleep 1
}
