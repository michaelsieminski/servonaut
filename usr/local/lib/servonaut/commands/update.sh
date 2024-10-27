#!/bin/bash

cmd_update() {
    check_root || exit 1

    echo -e "🔄 Checking for updates...\n"

    # Create temporary directory
    temp_dir=$(mktemp -d)
    cd "$temp_dir" || exit 1

    # Clone latest version
    if ! git clone --quiet https://github.com/michaelsieminski/servonaut.git; then
        echo -e "\n❌ Failed to check for updates"
        rm -rf "$temp_dir"
        exit 1
    fi

    cd servonaut || exit 1

    # Get current installed version (using git hash of last update)
    current_version="/usr/local/lib/servonaut/.version"
    if [ ! -f "$current_version" ]; then
        echo "first_install" >"$current_version"
    fi

    # Compare versions
    local_hash=$(cat "$current_version")
    remote_hash=$(git rev-parse HEAD)

    if [ "$local_hash" = "$remote_hash" ]; then
        echo -e "✅ Servonaut is already up to date!"
        rm -rf "$temp_dir"
        return 0
    fi

    echo -e "📦 Installing update...\n"

    # Update files
    mkdir -p /usr/local/lib/servonaut/{commands,utils}

    # Copy new files
    cp -R usr/local/bin/servonaut /usr/local/bin/
    cp -R usr/local/lib/servonaut/* /usr/local/lib/servonaut/

    # Store new version
    echo "$remote_hash" >"$current_version"

    # Set permissions
    chmod +x /usr/local/bin/servonaut
    chmod +x /usr/local/lib/servonaut/commands/*.sh
    chmod +x /usr/local/lib/servonaut/utils/*.sh

    # Clean up
    cd / && rm -rf "$temp_dir"

    echo -e "\n✅ Servonaut has been updated successfully!"
    return 0
}
