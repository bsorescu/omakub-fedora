#!/bin/bash

# Exit on any error
set -e

# Install required dependencies (Fedora-specific, with fallback for other distros)
if command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y gcc make unzip gettext curl
elif command -v apt >/dev/null 2>&1; then
    sudo apt update
    sudo apt install -y gcc make unzip gettext curl
else
    echo "Error: Neither dnf nor apt found. Please install gcc, make, unzip, gettext, and curl manually."
    exit 1
fi

# Download and install Neovim
cd /tmp
NVIM_VERSION="v0.11.3"
NVIM_TARBALL="nvim-linux64.tar.gz"
NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_TARBALL}"

# Attempt to download the tarball
if ! curl -fLO "$NVIM_URL"; then
    echo "Error: Failed to download $NVIM_TARBALL from $NVIM_URL (HTTP 404 or other issue)."
    echo "Falling back to AppImage installation..."
    NVIM_APPIMAGE="nvim.appimage"
    NVIM_APPIMAGE_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_APPIMAGE}"
    if ! curl -fLO "$NVIM_APPIMAGE_URL"; then
        echo "Error: Failed to download $NVIM_APPIMAGE from $NVIM_APPIMAGE_URL."
        echo "Please check https://github.com/neovim/neovim/releases for available assets."
        exit 1
    fi
    chmod u+x "$NVIM_APPIMAGE"
    sudo mv "$NVIM_APPIMAGE" /usr/local/bin/nvim
else
    # Extract and install tarball
    tar -xf "$NVIM_TARBALL"
    if [ ! -d "nvim-linux64" ]; then
        echo "Error: Tarball did not contain expected nvim-linux64 directory."
        exit 1
    fi
    sudo install nvim-linux64/bin/nvim /usr/local/bin/nvim
    sudo cp -R nvim-linux64/lib /usr/local/
    sudo cp -R nvim-linux64/share /usr/local/
    rm -rf nvim-linux64 "$NVIM_TARBALL"
fi
cd -

# Only configure LazyVim if Neovim config doesn't exist
if [ ! -d "$HOME/.config/nvim" ]; then
    # Install LazyVim
    git clone https://github.com/LazyVim/starter ~/.config/nvim || {
        echo "Error: Failed to clone LazyVim."
        exit 1
    }
    # Remove the .git folder to allow adding to user's own repo
    rm -rf ~/.config/nvim/.git

    # Set up transparency (check if omakub files exist)
    if [ -f ~/.local/share/omakub/configs/neovim/transparency.lua ]; then
        mkdir -p ~/.config/nvim/plugin/after
        cp ~/.local/share/omakub/configs/neovim/transparency.lua ~/.config/nvim/plugin/after/
    else
        echo "Warning: Omakub transparency.lua not found at ~/.local/share/omakub/configs/neovim/transparency.lua"
    fi

    # Set Tokyo Night theme (check if omakub theme exists)
    if [ -f ~/.local/share/omakub/themes/tokyo-night/neovim.lua ]; then
        cp ~/.local/share/omakub/themes/tokyo-night/neovim.lua ~/.config/nvim/lua/plugins/theme.lua
    else
        echo "Warning: Omakub Tokyo Night theme not found at ~/.local/share/omakub/themes/tokyo-night/neovim.lua"
    fi

    # Enable default LazyVim extras (check if omakub config exists)
    if [ -f ~/.local/share/omakub/configs/neovim/lazyvim.json ]; then
        cp ~/.local/share/omakub/configs/neovim/lazyvim.json ~/.config/nvim/lazyvim.json
    else
        echo "Warning: Omakub lazyvim.json not found at ~/.local/share/omakub/configs/neovim/lazyvim.json"
    fi
fi

# Replace desktop launcher with one running inside Ghostty (if applicable)
if [ -d ~/.local/share/applications ]; then
    sudo rm -rf /usr/share/applications/nvim.desktop || true
    if [ -f ~/.local/share/omakub/applications/Neovim.sh ]; then
        source ~/.local/share/omakub/applications/Neovim.sh
    else
        echo "Warning: Omakub Neovim.sh not found at ~/.local/share/omakub/applications/Neovim.sh"
    fi
fi

echo "Neovim installation and configuration completed successfully!" 	 	  	 	 	
