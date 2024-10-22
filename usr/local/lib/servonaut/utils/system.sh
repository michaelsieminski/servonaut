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
