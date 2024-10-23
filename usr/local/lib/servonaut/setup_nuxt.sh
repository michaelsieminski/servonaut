#!/bin/bash

setup_nuxt() {
    echo -e "📁 Setting up Nuxt project directory\n"
    mkdir -p /var/www/app
    chown servonaut:servonaut /var/www/app
    cd /var/www/app

    setup_github_auth
    repo_url=$(cat /home/servonaut/.repo_url)

    echo -e "📥 Cloning repository...\n"
    if ! sudo -u servonaut bash -c "GIT_SSH_COMMAND='ssh -i /home/servonaut/.ssh/id_ed25519 -o StrictHostKeyChecking=no' git clone '$repo_url' ."; then
        echo -e "\n❌ Failed to clone the repository. Please check the URL and your SSH key setup.\n"
        exit 1
    fi

    chown -R servonaut:servonaut /var/www/app

    echo -e "\n📦 Installing dependencies...\n"
    sudo -u servonaut /home/servonaut/.bun/bin/bun install

    echo -e "\n🏗️  Building the Nuxt project...\n"
    sudo -u servonaut /home/servonaut/.bun/bin/bun run build

    echo -e "\n🔧 Creating systemd service for Nuxt..."
    cat >/etc/systemd/system/nuxt.service <<EOF
[Unit]
Description=Nuxt Application
After=network.target

[Service]
Type=simple
User=servonaut
WorkingDirectory=/var/www/app
ExecStart=/home/servonaut/.bun/bin/bun run start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\n🚀 Enabling and starting Nuxt service..."
    systemctl enable nuxt.service
    systemctl start nuxt.service

    echo -e "\n🔧 Setting up GitHub webhook for automatic deployments..."
    domain_name=$(cat /home/servonaut/.domain_name)
    setup_github_webhook "$domain_name"

    return 0
}
