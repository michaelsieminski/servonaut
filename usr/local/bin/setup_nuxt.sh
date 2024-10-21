#!/bin/bash

setup_nuxt() {
    # Setup nuxt project directory
    mkdir -p /var/www/app
    cd /var/www/app

    # Ask for the repository URL
    read -p "Enter your GitHub repository URL (HTTPS or SSH): " repo_url

    # Setup SSH key if it's a private repository
    if [[ $repo_url == git@github.com:* ]]; then
        setup_ssh_key
    fi

    # Clone the repo
    if ! git clone "$repo_url" .; then
        echo "Failed to clone the repository. Please check the URL and your SSH key setup."
        exit 1
    fi

    # Install dependencies
    bun install

    # Build the nuxt project
    bun run build

    # Create a systemd service for the nuxt project
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

    systemctl enable nuxt.service
    systemctl start nuxt.service
}