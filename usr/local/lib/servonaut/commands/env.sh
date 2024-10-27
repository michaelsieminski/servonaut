#!/bin/bash

cmd_env() {
    case "$1" in
    "list")
        list_env_variables
        ;;
    "add")
        if [ -z "$2" ]; then
            echo -e "❌ Missing KEY=VALUE pair\n"
            echo "Usage: servonaut env add KEY=VALUE"
            return 1
        fi
        add_env_variable "$2"
        ;;
    *)
        echo -e "❌ Unknown command: servonaut env $1\n"
        source "/usr/local/lib/servonaut/commands/help.sh"
        cmd_help
        return 1
        ;;
    esac
}

add_env_variable() {
    local pair=$1

    # Validate format
    if [[ ! $pair =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; then
        echo -e "❌ Invalid format. Must be KEY=VALUE\n"
        echo "Example: servonaut env add DATABASE_URL=postgresql://user:pass@localhost:5432/db"
        return 1
    fi

    # Create .env if it doesn't exist
    if [ ! -f "/var/www/app/.env" ]; then
        echo -e "📝 No .env file found. Creating one...\n"
        sudo -u servonaut touch /var/www/app/.env
        chmod 600 /var/www/app/.env
    fi

    # Extract key from the pair
    local key=${pair%%=*}

    # Remove existing line with same key if it exists
    sudo -u servonaut sed -i "/^${key}=/d" /var/www/app/.env

    # Add new variable
    echo "$pair" | sudo -u servonaut tee -a /var/www/app/.env >/dev/null

    echo -e "✅ Environment variable added successfully!\n"

    # Restart Nuxt service to apply changes
    if systemctl is-active --quiet nuxt.service; then
        echo "🔄 Restarting Nuxt service to apply changes..."
        sudo systemctl restart nuxt.service
        echo -e "✅ Nuxt service restarted!\n"
    fi

    return 0
}

list_env_variables() {
    if [ ! -f "/var/www/app/.env" ]; then
        echo -e "📝 No .env file found. Creating one...\n"

        # Create .env file with proper permissions
        sudo -u servonaut touch /var/www/app/.env
        chmod 600 /var/www/app/.env

        echo -e "✅ Empty .env file created successfully!\n"
        echo -e "Use 'servonaut env add KEY=VALUE' to add environment variables.\n"
        return 0
    fi

    echo -e "📝 Environment Variables\n"

    printf "┌────────────────────────────────┬──────────────────────────┐\n"
    printf "│ %-30s │ %-20s │\n" "Variable" "Value"
    printf "├────────────────────────────────┼──────────────────────────┤\n"

    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        if [[ -z "$key" || "$key" =~ ^# ]]; then
            continue
        fi
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)

        # Truncate key and value if too long
        if [ ${#key} -gt 30 ]; then
            key="${key:0:27}..."
        fi
        if [ ${#value} -gt 20 ]; then
            value="${value:0:17}..."
        fi
        printf "│ %-30s │ %-20s │\n" "$key" "$value"
    done <"/var/www/app/.env"

    printf "└────────────────────────────────┴──────────────────────────┘\n"

}
