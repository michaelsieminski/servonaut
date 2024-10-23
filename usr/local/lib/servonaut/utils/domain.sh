#!/bin/bash

setup_domain() {
    echo -e "📝 Domain Configuration\n"

    while true; do
        read -p "Enter your domain name (e.g., example.com): " domain_name
        echo ""

        if [[ ! $domain_name =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo -e "\n❌ Invalid domain name. Please enter a valid domain.\n"
            continue
        fi

        # Store domain name for later use
        echo "$domain_name" >/home/servonaut/.domain_name
        chmod 600 /home/servonaut/.domain_name
        chown servonaut:servonaut /home/servonaut/.domain_name

        server_ip=$(get_server_ip)

        echo -e "Please create the following A record for your domain:\n"
        printf "┌───────┬──────┬────────────────────────────┐\n"
        printf "│ %-5s │ %-4s │ %-26s │\n" "Host" "Type" "Value"
        printf "├───────┼──────┼────────────────────────────┤\n"
        printf "│ %-5s │ %-4s │ %-26s │\n" "@" "A" "$server_ip"
        printf "└───────┴──────┴────────────────────────────┘\n"

        read -p "Have you added this A record? (yes/no): " dns_confirmation
        echo ""

        if [[ $dns_confirmation =~ ^[Yy][Ee]?[Ss]?$ ]]; then
            echo -e "🔍 Checking DNS propagation... This may take a moment.\n"
            sleep 2
            if check_dns "$domain_name" "$server_ip"; then
                echo -e "\n✅ DNS record verified successfully."
                break
            else
                echo -e "\n⚠️  The domain does not yet point to the correct IP address."
                echo -e "   This could be due to DNS propagation delay.\n"
                echo -e "   Options:"
                echo -e "   1. Wait and try again (recommended)"
                echo -e "   2. Continue anyway (may cause issues with HTTPS setup)\n"
                read -p "Do you want to continue anyway? (yes/no): " continue_anyway
                echo ""
                if [[ $continue_anyway =~ ^[Yy][Ee]?[Ss]?$ ]]; then
                    break
                fi
            fi
        else
            echo -e "\nPlease add the A record before continuing.\n"
        fi
    done

    return 0
}
