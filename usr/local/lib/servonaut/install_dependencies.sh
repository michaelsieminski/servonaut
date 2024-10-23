#!/bin/bash

install_dependencies() {
    if apt install -y curl unzip git; then
        echo -e "\n✅ Required packages installed successfully\n"
    else
        echo -e "\n⚠️  Some issues occurred during package installation\n"
        return 1
    fi
    sleep 1

    # Install Node.js for package compatibility
    echo -e "📦 Installing Node.js for package compatibility...\n"
    if curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs; then
        echo -e "\n✅ Node.js installed successfully"
    else
        echo -e "\n❌ Failed to install Node.js\n"
        return 1
    fi

    echo -e "\n🚀 Installing Bun...\n"
    # Create .bun directory with correct permissions
    sudo -u servonaut mkdir -p /home/servonaut/.bun
    if sudo -u servonaut bash -c 'curl -fsSL https://bun.sh/install | bash'; then
        echo -e "\n✅ Bun installed successfully"
        # Add Bun to PATH for the servonaut user
        sudo -u servonaut bash -c 'echo "export BUN_INSTALL=\"$HOME/.bun\"" >> $HOME/.bashrc'
        sudo -u servonaut bash -c 'echo "export PATH=\"$HOME/.bun/bin:$PATH\"" >> $HOME/.bashrc'
    else
        echo -e "\n❌ Failed to install Bun\n"
        return 1
    fi

    echo -e "\n✅ All dependencies installed successfully"
}
