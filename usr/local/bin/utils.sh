#!/bin/bash

check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo "This script must be run as root" 1>&2
        exit 1
    fi
}

update_system() {
    apt update && apt upgrade -y
}

setup_ssh_key() {
    # Generate SSH key
    ssh-keygen -t ed25519 -C "servonaut@deployment" -f /root/.ssh/id_ed25519 -N ""

    # Display the public key
    echo "Please add the following public key to your GitHub repository's deploy keys:"
    cat /root/.ssh/id_ed25519.pub
    echo ""
    echo "Press Enter when you have added the key to continue..."
    read -r

    # Add GitHub to known hosts
    ssh-keyscan github.com >> /root/.ssh/known_hosts
}