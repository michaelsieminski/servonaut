#!/bin/bash

select_database() {
    # Save current terminal settings
    saved_stty=$(stty -g)

    # Configure terminal for menu
    stty raw -echo

    # Available options
    options=("None" "PostgreSQL")
    selected=0

    while true; do
        # Clear screen
        echo -e "\033[2J\033[H"
        echo -e "🗄️  Select a database to install:\n"

        # Display options
        for i in "${!options[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "\033[36m> ${options[$i]}\033[0m"
            else
                echo "  ${options[$i]}"
            fi
        done

        # Read key press
        read -r -n1 key

        case $key in
        A) # Up arrow
            if [ $selected -gt 0 ]; then
                selected=$((selected - 1))
            fi
            ;;
        B) # Down arrow
            if [ $selected -lt $((${#options[@]} - 1)) ]; then
                selected=$((selected + 1))
            fi
            ;;
        '') # Enter key
            break
            ;;
        esac
    done

    # Restore terminal settings
    stty $saved_stty

    # Store selection
    echo "${options[$selected]}" >/home/servonaut/.database_choice
    chmod 600 /home/servonaut/.database_choice
    chown servonaut:servonaut /home/servonaut/.database_choice

    echo -e "\n✅ Database selection saved: ${options[$selected]}"
    return 0
}

setup_postgres() {
    echo -e "\n📦 Installing PostgreSQL...\n"

    # Install PostgreSQL
    apt-get install -y postgresql postgresql-contrib

    # Generate secure password for postgres user
    db_password=$(openssl rand -base64 24)
    echo "$db_password" >/home/servonaut/.db_password
    chmod 600 /home/servonaut/.db_password
    chown servonaut:servonaut /home/servonaut/.db_password

    # Start PostgreSQL service
    systemctl enable postgresql
    systemctl start postgresql

    # Create database and user
    sudo -u postgres psql -c "CREATE USER servonaut WITH PASSWORD '$db_password';"
    sudo -u postgres psql -c "CREATE DATABASE servonaut OWNER servonaut;"

    # Get server IP
    server_ip=$(get_server_ip)

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
    echo "postgres://servonaut:$db_password@$server_ip:5432/servonaut"

    echo -e "\n⚠️  Make sure to save these credentials securely!"
    echo -e "Press ENTER to continue..."
    read -r

    return 0
}
