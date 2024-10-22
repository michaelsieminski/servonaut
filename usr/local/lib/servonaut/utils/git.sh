#!/bin/bash

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
