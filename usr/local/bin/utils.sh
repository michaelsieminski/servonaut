#!/bin/bash

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "❌ This script must be run as root\n"
        exit 1
    fi
}

update_system() {
    if apt update && apt upgrade -y; then
        echo -e "\n✅ System packages updated successfully\n"
    else
        echo -e "\n⚠️  Some issues occurred during system update\n"
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

    echo -e "\n🔒 Adding GitHub to known hosts...\n"
    ssh-keyscan github.com >>/root/.ssh/known_hosts
    echo -e "\n✅ SSH key setup completed\n"
    sleep 1
}

get_server_ip() {
    local ipv4=$(curl -s4 ifconfig.me)
    if [ -n "$ipv4" ]; then
        echo "$ipv4"
    else
        curl -s6 ifconfig.me
    fi
}

check_dns() {
    local domain=$1
    local expected_ip=$2
    echo -e "🔍 Checking DNS propagation for $domain...\n"
    local resolved_ip=$(dig +short $domain)

    if [ "$resolved_ip" = "$expected_ip" ]; then
        echo -e "\n✅ DNS propagation successful\n"
        return 0
    else
        echo -e "\n⚠️  DNS propagation not complete yet\n"
        return 1
    fi
    sleep 1
}
