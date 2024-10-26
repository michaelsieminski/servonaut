#!/bin/bash

setup_servonaut_user() {
    if id "servonaut" &>/dev/null; then
        echo -e "\n✅ User 'servonaut' already exists. Skipping user creation."
        return 0
    else
        # Generate a random password
        password=$(openssl rand -base64 12)

        # Create the new user
        useradd -m -s /bin/bash servonaut || return 1

        # Set the password for the new user
        echo "servonaut:$password" | chpasswd || return 1

        # Add user to sudo group
        usermod -aG sudo servonaut || return 1

        # Create .ssh directory for the new user
        mkdir -p /home/servonaut/.ssh || return 1
        cp /root/.ssh/authorized_keys /home/servonaut/.ssh/authorized_keys || return 1
        chown -R servonaut:servonaut /home/servonaut/.ssh || return 1
        chmod 700 /home/servonaut/.ssh || return 1
        chmod 600 /home/servonaut/.ssh/authorized_keys || return 1

        echo -e "\n✅ Non-root user 'servonaut' has been created successfully."
        echo -e "📝 Please note down the following credentials:"
        echo -e "   Username: servonaut"
        echo -e "   Password: $password"

        read -p "Press Enter if you have noted down the credentials"
        return 0
    fi
}

setup_automatic_security_updates() {
    echo -e "🛡️  Setting up automatic security updates...\n"

    # Install unattended-upgrades package
    apt-get install -y unattended-upgrades

    # Configure unattended-upgrades
    cat >/etc/apt/apt.conf.d/50unattended-upgrades <<EOF
Unattended-Upgrade::Allowed-Origins {
    "\${distro_id}:\${distro_codename}";
    "\${distro_id}:\${distro_codename}-security";
    "\${distro_id}ESMApps:\${distro_codename}-apps-security";
    "\${distro_id}ESM:\${distro_codename}-infra-security";
};
Unattended-Upgrade::Package-Blacklist {
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::InstallOnShutdown "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    # Enable automatic updates
    echo 'APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";' >/etc/apt/apt.conf.d/20auto-upgrades

    echo -e "\n✅ Automatic security updates have been set up successfully."
    return 0
}

setup_fail2ban() {
    echo -e "🛡️  Setting up fail2ban to protect against brute-force attacks...\n"

    # Install fail2ban
    apt-get install -y fail2ban

    # Create a custom jail for SSH
    cat >/etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
findtime = 600
EOF

    # Restart fail2ban to apply changes
    systemctl restart fail2ban

    echo -e "\n✅ fail2ban has been set up successfully to protect against SSH brute-force attacks."
    return 0
}

setup_ufw() {
    echo -e "🛡️ Setting up UFW (Firewall)...\n"

    # Install UFW if not already installed
    apt-get install -y ufw

    # Reset UFW to default settings
    ufw --force reset

    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing

    # Allow SSH (port 22)
    ufw allow ssh

    # Allow HTTP (port 80) and HTTPS (port 443) for web traffic
    ufw allow http
    ufw allow https

    # Allow Webhook Service
    ufw allow 9000/tcp

    # Rate limit SSH connections
    ufw limit ssh

    # Allow PostgreSQL if installed
    if [ -f "/home/servonaut/.database_choice" ] && [ "$(cat /home/servonaut/.database_choice)" = "PostgreSQL" ]; then
        ufw allow 5432/tcp
    fi

    # Enable UFW
    echo "y" | ufw enable

    echo -e "\n✅ UFW has been set up successfully."
    return 0
}

setup_ssh_security() {
    echo -e "🔒 Hardening SSH configuration...\n"

    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

    # Configure SSH security settings
    cat >/etc/ssh/sshd_config <<EOF
Port 22
Protocol 2
PermitRootLogin no
MaxAuthTries 3
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers servonaut
EOF

    # Restart SSH service
    systemctl restart sshd

    echo -e "\n✅ SSH has been hardened successfully."
    return 0
}

setup_system_security() {
    echo -e "🛡️ Configuring system security...\n"

    # Configure sysctl security settings
    cat >/etc/sysctl.d/99-security.conf <<EOF
# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP broadcast requests
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Block SYN attacks
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 5

# Log Martians
net.ipv4.conf.all.log_martians = 1

# Disable IPv6 if not needed
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF

    # Apply sysctl settings
    sysctl -p /etc/sysctl.d/99-security.conf

    # Secure shared memory
    echo "tmpfs     /run/shm     tmpfs     defaults,noexec,nosuid     0     0" >>/etc/fstab

    echo -e "\n✅ System security settings have been configured."
    return 0
}

setup_crowdsec() {
    echo -e "🛡️  Setting up CrowdSec...\n"

    # Install CrowdSec
    curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash
    apt-get install -y crowdsec

    # Install bouncer
    apt-get install -y crowdsec-firewall-bouncer-iptables

    # Enable and start CrowdSec
    systemctl enable crowdsec
    systemctl start crowdsec

    # Configure CrowdSec to watch Caddy logs
    cscli collections install crowdsecurity/caddy
    systemctl restart crowdsec

    echo -e "\n✅ CrowdSec has been set up successfully."
    return 0
}
