#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    echo "❌ This script must be run as root"
    exit 1
fi

# Define the source directory (the current directory where the script is run)
source_dir=$(dirname "$0")

# Copy the scripts to the appropriate locations
cp -R "$source_dir/usr/local/bin/"* /usr/local/bin/
cp -R "$source_dir/usr/local/lib/servonaut/"* /usr/local/lib/servonaut/

# Make sure all scripts are executable
chmod +x /usr/local/bin/servonaut*
chmod +x /usr/local/lib/servonaut/*.sh
chmod +x /usr/local/lib/servonaut/utils/*.sh

echo "✅ Servonaut has been installed successfully!"
