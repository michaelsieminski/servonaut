install_dependencies() {
    if apt install -y curl unzip git; then
        echo -e "\n✅ Required packages installed successfully\n"
    else
        echo -e "\n⚠️  Some issues occurred during package installation\n"
        return 1
    fi
    sleep 1

    echo -e "🚀 Installing Bun...\n"
    # Create .bun directory with correct permissions
    sudo -u servonaut mkdir -p /home/servonaut/.bun
    if sudo -u servonaut bash -c 'curl -fsSL https://bun.sh/install | bash'; then
        echo -e "\n✅ Bun installed successfully"
        # Add Bun to PATH for the servonaut user
        sudo -u servonaut bash -c 'echo "export BUN_INSTALL=\"$HOME/.bun\"" >> $HOME/.bashrc'
        sudo -u servonaut bash -c 'echo "export PATH=\"$HOME/.bun/bin:$PATH\"" >> $HOME/.bashrc'
        # Source the updated .bashrc to make Bun available immediately
        sudo -u servonaut bash -c 'source $HOME/.bashrc'
    else
        echo -e "\n❌ Failed to install Bun\n"
        return 1
    fi

    echo -e "\n✅ All dependencies installed successfully"
}
