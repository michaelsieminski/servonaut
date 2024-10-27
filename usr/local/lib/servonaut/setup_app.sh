#!/bin/bash

setup_app() {
    echo -e "📁 Setting up application directory\n"

    # Check if app directory exists and remove it if it does
    if [ -d "/var/www/app" ]; then
        echo -e "🗑️  Removing existing app directory...\n"
        rm -rf /var/www/app
    fi

    mkdir -p /var/www/app
    chown -R servonaut:servonaut /var/www/app
    chmod -R 755 /var/www/app
    cd /var/www/app

    # Set up temporary directories with proper permissions
    mkdir -p /tmp/servonaut
    chown -R servonaut:servonaut /tmp/servonaut
    chmod -R 755 /tmp/servonaut

    setup_github_auth
    repo_url=$(cat /home/servonaut/.repo_url)

    echo -e "📥 Cloning repository...\n"
    if ! sudo -u servonaut bash -c "GIT_SSH_COMMAND='ssh -i /home/servonaut/.ssh/id_ed25519 -o StrictHostKeyChecking=no' git clone '$repo_url' ."; then
        echo -e "\n❌ Failed to clone the repository. Please check the URL and your SSH key setup.\n"
        exit 1
    fi

    echo -e "\n📦 Installing dependencies...\n"
    sudo -u servonaut bash -c 'cd /var/www/app && TMPDIR=/tmp/servonaut /home/servonaut/.bun/bin/bun install'

    echo -e "\n🏗️  Building the application...\n"
    sudo -u servonaut bash -c 'cd /var/www/app && \
        export PATH="/home/servonaut/.bun/bin:$PATH" && \
        export BUN_INSTALL="/home/servonaut/.bun" && \
        TMPDIR=/tmp/servonaut NODE_OPTIONS="--no-warnings" /home/servonaut/.bun/bin/bun run build || true'

    # Ensure permissions are maintained after build
    chown -R servonaut:servonaut /var/www/app
    chmod -R 755 /var/www/app

    echo -e "\n🔧 Creating systemd service for application..."
    cat >/etc/systemd/system/app.service <<EOF
[Unit]
Description=Web Application
After=network.target

[Service]
Type=simple
User=servonaut
WorkingDirectory=/var/www/app
Environment="PATH=/home/servonaut/.bun/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="BUN_INSTALL=/home/servonaut/.bun"
ExecStart=/home/servonaut/.bun/bin/bun run start
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\n🚀 Enabling and starting application service..."
    systemctl enable app.service
    systemctl start app.service

    echo -e "\n🔧 Setting up GitHub webhook for automatic deployments..."
    domain_name=$(cat /home/servonaut/.domain_name)
    setup_github_webhook "$domain_name"

    return 0
}
