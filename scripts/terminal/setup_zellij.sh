#!/bin/bash

# Setup script for zellij terminal multiplexer

set -e

echo "Installing zellij..."

# Check if cargo is installed
if command -v cargo &> /dev/null; then
    echo "Installing zellij via cargo..."
    cargo install --locked zellij
elif command -v wget &> /dev/null; then
    echo "Installing zellij via binary download..."
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        ZELLIJ_ARCH="x86_64-unknown-linux-musl"
    elif [ "$ARCH" = "aarch64" ]; then
        ZELLIJ_ARCH="aarch64-unknown-linux-musl"
    else
        echo "Unsupported architecture: $ARCH"
        exit 1
    fi

    # Download latest release
    ZELLIJ_VERSION=$(curl -s https://api.github.com/repos/zellij-org/zellij/releases/latest | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
    DOWNLOAD_URL="https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${ZELLIJ_ARCH}.tar.gz"

    echo "Downloading zellij v${ZELLIJ_VERSION}..."
    wget -O /tmp/zellij.tar.gz "$DOWNLOAD_URL"

    # Extract and install
    tar -xzf /tmp/zellij.tar.gz -C /tmp
    mkdir -p ~/.local/bin
    mv /tmp/zellij ~/.local/bin/
    chmod +x ~/.local/bin/zellij
    rm /tmp/zellij.tar.gz

    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        echo "Added ~/.local/bin to PATH in .bashrc"
    fi
else
    echo "Error: Neither cargo nor wget is available. Please install one of them first."
    exit 1
fi

echo "Zellij installation complete!"
echo "Run 'source ~/.bashrc' or open a new terminal to use zellij."
