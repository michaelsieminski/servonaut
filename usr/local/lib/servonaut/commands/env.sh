#!/bin/bash

cmd_env() {
    case "$1" in
    "list")
        list_env_variables
        ;;
    *)
        cmd_help
        return 1
        ;;
    esac
}

list_env_variables() {
    if [ ! -f "/var/www/app/.env" ]; then
        echo -e "❌ No .env file found in your project"
        return 1
    fi

    echo -e "📝 Environment Variables\n"

    printf "┌────────────────────────────┬────────────────────────────┐\n"
    printf "│ %-24s │ %-24s │\n" "Variable" "Value"
    printf "├────────────────────────────┼────────────────────────────┤\n"

    while IFS='=' read -r key value; do
        # Skip empty lines and comments
        if [[ -z "$key" || "$key" =~ ^# ]]; then
            continue
        fi
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        if [ ${#value} -gt 24 ]; then
            value="${value:0:21}..."
        fi
        printf "│ %-24s │ %-24s │\n" "$key" "$value"
    done <"/var/www/app/.env"

    printf "└────────────────────────────┴────────────────────────────┘\n"
}
