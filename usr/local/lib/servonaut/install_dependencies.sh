#!/bin/bash

install_dependencies() {
    if apt install -y curl unzip git; then
        echo -e "\n✅ Required packages installed successfully\n"
    else
        echo -e "\n⚠️  Some issues occurred during package installation\n"
        return 1
    fi
    sleep 1

    echo -e "🚀 Installing Bun...\n"
    if curl -fsSL https://bun.sh/install | bash; then
        echo -e "\n✅ Bun installed successfully"
        # Add Bun to PATH for the current session
        export BUN_INSTALL="/root/.bun"
        export PATH="/root/.bun/bin:$PATH"
        # Add Bun to PATH permanently
        echo 'export BUN_INSTALL="/root/.bun"' >>/root/.bashrc
        echo 'export PATH="/root/.bun/bin:$PATH"' >>/root/.bashrc
        source /root/.bashrc
    else
        echo -e "\n❌ Failed to install Bun\n"
        return 1
    fi

    echo -e "\n✅ All dependencies installed successfully"
}
