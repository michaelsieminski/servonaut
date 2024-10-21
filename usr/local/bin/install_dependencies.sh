#!/bin/bash

install_dependencies() {
    # Install required packages
    apt install -y curl unzip git

    # Install Bun
    curl -fsSL https://bun.sh/install | bash
}