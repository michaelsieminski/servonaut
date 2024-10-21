#!/bin/bash

setup_nuxt() {
    echo -e "📁 Setting up Nuxt project directory\n"
    mkdir -p /var/www/app
    cd /var/www/app

    echo -e "🔗 GitHub Repository Configuration\n"
    read -p "Enter your GitHub repository SSH URL: " repo_url
    echo ""

    if [[ $repo_url == git@github.com:* ]]; then
        echo -e "🔑 Setting up SSH key for private repository\n"
        setup_ssh_key
    fi

    echo -e "📥 Cloning repository...\n"
    if ! git clone "$repo_url" .; then
        echo -e "❌ Failed to clone the repository. Please check the URL and your SSH key setup.\n"
        exit 1
    fi

    echo -e "📦 Installing dependencies...\n"
    bun install

    echo -e "🏗️  Building the Nuxt project...\n"
    bun run build

    echo -e "🔧 Creating systemd service for Nuxt...\n"
    cat > /etc/systemd/system/nuxt.service << EOF
[Unit]
Description=Nuxt Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/app
ExecStart=/root/.bun/bin/bun run start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    echo -e "🚀 Enabling and starting Nuxt service...\n"
    systemctl enable nuxt.service
    systemctl start nuxt.service
}