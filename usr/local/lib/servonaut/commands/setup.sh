#!/bin/bash

source /usr/local/lib/servonaut/install_dependencies.sh
source /usr/local/lib/servonaut/security.sh
source /usr/local/lib/servonaut/setup_caddy.sh
source /usr/local/lib/servonaut/setup_app.sh
source /usr/local/lib/servonaut/setup_webhook.sh
source /usr/local/lib/servonaut/setup_database.sh

cmd_setup() {
    clear
    check_root || exit 1
    check_architecture || exit 1

    echo -e "\n🔄 Updating system packages...\n"
    sleep 1
    update_system || {
        echo -e "\n❌ Failed to update system packages. Exiting."
        exit 1
    }

    echo -e "\n🔄 Setting up servonaut user...\n"
    sleep 1
    setup_servonaut_user || {
        echo -e "\n❌ Failed to set up servonaut user. Exiting."
        exit 1
    }

    echo -e "\n🔄 Installing dependencies...\n"
    sleep 1
    install_dependencies || {
        echo -e "\n❌ Failed to install dependencies. Exiting."
        exit 1
    }

    echo -e "\n🔄 Setting up domain...\n"
    sleep 1
    setup_domain || {
        echo -e "\n❌ Failed to set up domain. Exiting."
        exit 1
    }

    echo -e "\n🔄 Setting up database...\n"
    sleep 1
    select_database
    db_choice=$(cat /home/servonaut/.database_choice)
    if [ "$db_choice" = "PostgreSQL" ]; then
        setup_postgres || {
            echo -e "\n❌ Failed to set up PostgreSQL. Exiting."
            exit 1
        }
    elif [ "$db_choice" = "MySQL" ]; then
        setup_mysql || {
            echo -e "\n❌ Failed to set up MySQL. Exiting."
            exit 1
        }
    elif [ "$db_choice" = "MariaDB" ]; then
        setup_mariadb || {
            echo -e "\n❌ Failed to set up MariaDB. Exiting."
            exit 1
        }
    fi

    echo -e "\n🔄 Hardening the server...\n"
    sleep 1
    setup_system_security || {
        echo -e "\n❌ Failed to configure system security. Exiting."
        exit 1
    }
    setup_ssh_security || {
        echo -e "\n❌ Failed to harden SSH. Exiting."
        exit 1
    }
    setup_automatic_security_updates || {
        echo -e "\n❌ Failed to set up automatic security updates. Exiting."
        exit 1
    }
    setup_fail2ban || {
        echo -e "\n❌ Failed to set up fail2ban. Exiting."
        exit 1
    }
    setup_crowdsec || {
        echo -e "\n❌ Failed to set up CrowdSec. Exiting."
        exit 1
    }
    setup_ufw || {
        echo -e "\n❌ Failed to set up UFW. Exiting."
        exit 1
    }

    echo -e "\n🔄 Setting up web application...\n"
    sleep 1
    setup_app || {
        echo -e "\n❌ Failed to set up web application. Exiting."
        exit 1
    }

    echo -e "\n🔄 Setting up Caddy web server...\n"
    sleep 1
    setup_caddy || {
        echo -e "\n❌ Failed to set up Caddy web server. Exiting."
        exit 1
    }

    echo -e "\n🔄 Setting up webhook handler...\n"
    sleep 1
    setup_webhook || {
        echo -e "\n❌ Failed to set up webhook handler. Exiting."
        exit 1
    }

    echo -e "\n🔄 Reloading systemd and restarting application service..."
    sleep 1
    systemctl daemon-reload
    systemctl restart app.service || {
        echo -e "\n❌ Failed to restart application service. Exiting."
        exit 1
    }

    echo -e "\n✅ Setup complete!\n"
    sleep 1
    echo -e "You can now access your application at https://$domain_name\n"
    echo -e "If you like Servonaut, please give us a star on GitHub: https://github.com/michaelsieminski/servonaut\n"
    echo -e "Thank you and happy coding! 🎉\n"
}
