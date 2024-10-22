#!/bin/bash

install_dependencies() {
    if apt install -y curl unzip git; then
        echo -e "\n✅ Required packages installed successfully\n"
    else
        echo -e "\n⚠️  Some issues occurred during package installation\n"
        return 1
    fi
    sleep 1

    echo -e "\n🚀 Installing Bun...\n"
    if curl -fsSL https://bun.sh/install | bash; then
        echo -e "\n✅ Bun installed successfully"
        # Add Bun to PATH for the current session
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        # Add Bun to PATH permanently
        echo 'export BUN_INSTALL="$HOME/.bun"' >>$HOME/.bashrc
        echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >>$HOME/.bashrc
        source $HOME/.bashrc
    else
        echo -e "\n❌ Failed to install Bun\n"
        return 1
    fi

    echo -e "\n✅ All dependencies installed successfully"
}
