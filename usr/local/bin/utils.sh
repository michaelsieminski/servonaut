#!/bin/bash

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "❌ This script must be run as root\n"
        exit 1
    fi
}

update_system() {
    echo -e "🔄 Updating system packages...\n"
    sleep 1
    if apt update && apt upgrade -y; then
        echo -e "✅ System packages updated successfully\n"
    else
        echo -e "⚠️  Some issues occurred during system update\n"
    fi
    sleep 1
}

setup_ssh_key() {
    echo -e "🔑 Generating SSH key for GitHub...\n"
    ssh-keygen -t ed25519 -C "servonaut@deployment" -f /root/.ssh/id_ed25519 -N ""

    echo -e "\n📋 Please add the following public key to your GitHub repository's deploy keys:\n"
    cat /root/.ssh/id_ed25519.pub
    echo -e "\n"
    read -p "Press Enter when you have added the key to continue..."
    echo -e "\n"

    echo -e "🔒 Adding GitHub to known hosts...\n"
    ssh-keyscan github.com >> /root/.ssh/known_hosts
    echo -e "✅ SSH key setup completed\n"
    sleep 1
}

get_server_ip() {
    curl -s ifconfig.me
}

check_dns() {
    local domain=$1
    local expected_ip=$2
    echo -e "🔍 Checking DNS propagation for $domain...\n"
    local resolved_ip=$(dig +short $domain)
    
    if [ "$resolved_ip" = "$expected_ip" ]; then
        echo -e "✅ DNS propagation successful\n"
        return 0
    else
        echo -e "⚠️  DNS propagation not complete yet\n"
        return 1
    fi
    sleep 1
}