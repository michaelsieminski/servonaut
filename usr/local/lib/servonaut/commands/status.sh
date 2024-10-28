#!/bin/bash

check_all_services() {
    local issues=()

    # Core Services
    systemctl is-active --quiet app.service || issues+=("app service")
    systemctl is-active --quiet caddy || issues+=("web server")
    systemctl is-active --quiet webhook || issues+=("webhook service")

    # Security Services
    systemctl is-active --quiet fail2ban || issues+=("fail2ban")
    systemctl is-active --quiet crowdsec || issues+=("crowdsec")
    systemctl is-active --quiet ufw || issues+=("firewall")

    # Database if installed
    if [ -f "/home/servonaut/.database_choice" ]; then
        local db_choice=$(cat /home/servonaut/.database_choice)
        case "$db_choice" in
        "PostgreSQL") systemctl is-active --quiet postgresql || issues+=("database") ;;
        "MySQL") systemctl is-active --quiet mysql || issues+=("database") ;;
        "MariaDB") systemctl is-active --quiet mariadb || issues+=("database") ;;
        esac
    fi

    if [ ${#issues[@]} -eq 0 ]; then
        return 0
    else
        echo "${issues[*]}"
        return 1
    fi
}

check_site() {
    local domain=$(cat /home/servonaut/.domain_name)
    curl -s -I "https://$domain" | grep -q "HTTP/2 200"
}

cmd_status() {
    clear
    printf "\n  🔍 SERVONAUT STATUS\n"
    printf "  ─────────────────\n\n"

    # Check if deployment is in progress
    if pgrep -f "auto_deploy.sh" >/dev/null; then
        printf "  🔄 Deployment in progress\n\n"
        exit 0
    fi

    # Check all services and site
    local service_status=$(check_all_services)
    local site_ok=0
    check_site && site_ok=1

    if [ $? -eq 0 ] && [ $site_ok -eq 1 ]; then
        printf "  ✅ All systems operational\n\n"
    else
        printf "  ❌ Issues detected:\n"
        [ $site_ok -eq 0 ] && printf "     • Site unreachable\n"
        [ -n "$service_status" ] && printf "     • Service issues: %s\n" "$service_status"
        printf "\n"
    fi
}
