#!/bin/bash

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
    echo -e "🔍 Checking DNS propagation for $domain..."
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
