#!/bin/bash

check_root() {
    if ! sudo -v &>/dev/null; then
        echo -e "❌ This command requires root privileges (either root user or sudo access)\n"
        return 1
    fi
    return 0
}

update_system() {
    if apt update && apt upgrade -y; then
        echo -e "\n✅ System packages updated successfully"
        return 0
    else
        echo -e "\n⚠️  Some issues occurred during system update"
        return 1
    fi
}

get_architecture() {
    arch=$(uname -m)
    case "$arch" in
    "x86_64")
        echo "x86"
        ;;
    "aarch64")
        echo "arm"
        ;;
    *)
        echo "unsupported"
        ;;
    esac
}

check_architecture() {
    arch=$(get_architecture)
    if [ "$arch" = "unsupported" ]; then
        echo -e "❌ Unsupported architecture. Servonaut supports x86_64 and ARM64 only.\n"
        return 1
    fi
    return 0
}
