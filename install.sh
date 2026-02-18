#!/bin/bash

# install.sh - Automates symlinking of dotfiles to your home directory.
# This script handles root dotfiles and nested .config directories.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Starting symlinking process from $DOTFILES_DIR..."

# Function to create symlink with backup
link_file() {
    local src=$1
    local dst=$2

    # Skip if source doesn't exist
    if [ ! -e "$src" ]; then
        return
    fi

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dst")"

    if [ -L "$dst" ]; then
        current_link=$(readlink "$dst")
        if [ "$current_link" == "$src" ]; then
            echo "✅ Already linked: $dst"
            return
        else
            echo "🔄 Updating symlink: $dst"
            rm "$dst"
        fi
    elif [ -e "$dst" ]; then
        echo "📦 Backing up: $dst -> ${dst}.bak"
        mv "$dst" "${dst}.bak"
    fi

    echo "🔗 Linking: $src -> $dst"
    ln -s "$src" "$dst"
}

# --- Root Dotfiles ---
# Common files at the root of the repo
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/.tmux" "$HOME/.tmux"

# --- ZSH (if organized in zsh/ subdir) ---
if [ -d "$DOTFILES_DIR/zsh" ]; then
    link_file "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    link_file "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
fi

# --- Automatically handle .config directories ---
# Find directories that contain a .config folder (like nvim/ and karabiner/)
# and symlink their contents to ~/.config/
find "$DOTFILES_DIR" -maxdepth 2 -name ".config" -type d | while read -r config_parent; do
    for item in "$config_parent"/*; do
        if [ -e "$item" ]; then
            basename_item=$(basename "$item")
            link_file "$item" "$HOME/.config/$basename_item"
        fi
    done
done

# --- Aerospace (Special case at root-level subdir) ---
link_file "$DOTFILES_DIR/aerospace/.aerospace.toml" "$HOME/.aerospace.toml"

echo "✨ Symlinking complete! You might need to restart your terminal or source your .zshrc."
