#!/bin/bash

select_database() {
    # Available options
    options=("No database" "PostgreSQL (recommended for production)" "MySQL")

    # Call select_option with more friendly messages
    select_option "Would you like to install a database?" "Use arrow keys to select an option, Enter to confirm" "${options[@]}"
    selected=$?

    # Convert friendly names back to internal names
    case "${options[$selected]}" in
    "No database")
        choice="None"
        ;;
    "PostgreSQL (recommended for production)")
        choice="PostgreSQL"
        ;;
    "MySQL")
        choice="MySQL"
        ;;
    esac

    # Store selection
    echo "$choice" >/home/servonaut/.database_choice
    chmod 600 /home/servonaut/.database_choice
    chown servonaut:servonaut /home/servonaut/.database_choice

    if [ "$choice" = "None" ]; then
        echo -e "\n✓ No database will be installed\n"
    else
        echo -e "\n✓ Selected: $choice\n"
    fi
    return 0
}

setup_postgres() {
    echo -e "\n📦 Installing PostgreSQL...\n"

    # Install PostgreSQL
    apt-get install -y postgresql postgresql-contrib

    # Configure PostgreSQL to listen on all interfaces
    pg_version=$(ls /etc/postgresql/)
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/$pg_version/main/postgresql.conf

    # Allow remote connections
    echo "host    all             all             0.0.0.0/0               md5" >>/etc/postgresql/$pg_version/main/pg_hba.conf

    # Generate secure password for postgres user
    db_password=$(openssl rand -base64 24)
    echo "$db_password" >/home/servonaut/.db_password
    chmod 600 /home/servonaut/.db_password
    chown servonaut:servonaut /home/servonaut/.db_password

    # Check if user exists and update password, or create new user
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='servonaut'" | grep -q 1; then
        echo "User 'servonaut' exists, updating password..."
        sudo -u postgres psql -c "ALTER USER servonaut WITH PASSWORD '$db_password';"
    else
        echo "Creating new user 'servonaut'..."
        sudo -u postgres psql -c "CREATE USER servonaut WITH PASSWORD '$db_password';"
    fi

    # Check if database exists, create if it doesn't
    if ! sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw servonaut; then
        sudo -u postgres psql -c "CREATE DATABASE servonaut OWNER servonaut;"
    fi

    # Secure PostgreSQL configuration
    cat >>/etc/postgresql/$pg_version/main/postgresql.conf <<EOF
ssl = on
ssl_prefer_server_ciphers = on
ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL'
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
EOF

    # Restart PostgreSQL to apply changes
    systemctl restart postgresql
    systemctl enable postgresql

    # Get server IP
    server_ip=$(get_server_ip)

    # Verify PostgreSQL is running and accessible
    if ! netstat -tuln | grep -q ":5432 "; then
        echo -e "\n❌ PostgreSQL is not listening on port 5432. Please check the logs with 'journalctl -u postgresql'"
        return 1
    fi

    # Clear screen and show connection details
    clear
    echo -e "🎉 PostgreSQL Setup Complete!\n"

    printf "┌─────────────────────────────────────────────────────────────┐\n"
    printf "│ PostgreSQL Connection Details                               │\n"
    printf "├────────────────┬────────────────────────────────────────────┤\n"
    printf "│ Host           │ %-42s │\n" "$server_ip"
    printf "│ Port           │ %-42s │\n" "5432"
    printf "│ Database       │ %-42s │\n" "servonaut"
    printf "│ Username       │ %-42s │\n" "servonaut"
    printf "│ Password       │ %-42s │\n" "$db_password"
    printf "└────────────────┴────────────────────────────────────────────┘\n"

    echo -e "\n📋 TablePlus Connection URL:"
    echo "postgresql://servonaut:$db_password@$server_ip:5432/servonaut"

    echo -e "\n⚠️  Make sure to save these credentials securely!"
    echo -e "Press ENTER to continue..."
    read -r

    return 0
}

setup_mysql() {
    echo -e "\n📦 Installing MySQL...\n"

    # Generate passwords
    root_password=$(openssl rand -base64 24)
    db_password=$(openssl rand -base64 24)

    # Pre-configure MySQL installation
    debconf-set-selections <<EOF
mysql-server mysql-server/root_password password $root_password
mysql-server mysql-server/root_password_again password $root_password
mysql-server mysql-server/default_auth_override select Use_Strong_Password_Encryption
EOF

    # Install MySQL non-interactively
    DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server || {
        echo -e "\n❌ Failed to install MySQL"
        return 1
    }

    # Start MySQL service
    systemctl start mysql || {
        echo -e "\n❌ Failed to start MySQL service"
        return 1
    }

    # Secure the installation and create servonaut user/database
    mysql --user=root --password="$root_password" <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$root_password';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE servonaut;
CREATE USER 'servonaut'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON servonaut.* TO 'servonaut'@'localhost';
FLUSH PRIVILEGES;
EOF

    # Store database choice
    echo "MySQL" >/home/servonaut/.database_choice
    chmod 600 /home/servonaut/.database_choice
    chown servonaut:servonaut /home/servonaut/.database_choice

    # Get server IP
    server_ip=$(get_server_ip)

    echo -e "\n✅ MySQL installed and configured successfully!\n"
    echo -e "📝 Database Connection Details:\n"

    printf "┌─────────────────────────────────────────────────────────────┐\n"
    printf "│ MySQL Connection Details                                     │\n"
    printf "├────────────────┬────────────────────────────────────────────┤\n"
    printf "│ Host           │ %-42s │\n" "$server_ip"
    printf "│ Port           │ %-42s │\n" "3306"
    printf "│ Database       │ %-42s │\n" "servonaut"
    printf "│ Username       │ %-42s │\n" "servonaut"
    printf "│ Password       │ %-42s │\n" "$db_password"
    printf "└────────────────┴────────────────────────────────────────────┘\n"

    echo -e "\n📋 TablePlus Connection URL:"
    echo "mysql://servonaut:${db_password}@${server_ip}:3306/servonaut"

    echo -e "\n⚠️  Make sure to save these credentials securely!"
    echo -e "Press ENTER to continue..."
    read -r

    return 0
}
