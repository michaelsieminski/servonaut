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
    if sudo -u servonaut bash -c "curl -fsSL https://bun.sh/install | bash"; then
        echo -e "\n✅ Bun installed successfully"
        # Add Bun to PATH for the servonaut user
        echo 'export BUN_INSTALL="/home/servonaut/.bun"' >>/home/servonaut/.bashrc
        echo 'export PATH="/home/servonaut/.bun/bin:$PATH"' >>/home/servonaut/.bashrc
        source /home/servonaut/.bashrc
    else
        echo -e "\n❌ Failed to install Bun\n"
        return 1
    fi

    echo -e "\n✅ All dependencies installed successfully"
}
