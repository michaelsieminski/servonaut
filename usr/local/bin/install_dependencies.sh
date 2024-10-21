#!/bin/bash

install_dependencies() {
    if apt install -y curl unzip git; then
        echo -e "✅ Required packages installed successfully\n"
    else
        echo -e "⚠️  Some issues occurred during package installation\n"
        return 1
    fi
    sleep 1

    echo -e "🚀 Installing Bun...\n"
    if curl -fsSL https://bun.sh/install | bash; then
        echo -e "✅ Bun installed successfully\n"
    else
        echo -e "❌ Failed to install Bun\n"
        return 1
    fi
    sleep 1

    echo -e "✅ All dependencies installed successfully\n"
}