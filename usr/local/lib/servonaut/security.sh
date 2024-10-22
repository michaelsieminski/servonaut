#!/bin/bash

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

    # Enable UFW
    echo "y" | ufw enable

    echo -e "\n✅ UFW has been set up successfully with basic rules."
}
