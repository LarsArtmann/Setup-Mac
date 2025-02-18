#!/bin/bash

check_file_or_symlink() {
    local path="$1"
    local command="$2"

    if [ -e "$path" ]; then
        if [ -L "$path" ]; then
            echo "Error: A symbolic link already exists at $path."
        elif [ -f "$path" ]; then
            echo "Error: A regular file already exists at $path."
        else
            echo "Error: An entry already exists at $path, but it is neither a regular file nor a symbolic link."
        fi
    else
        echo "No file or symbolic link exists at $path. Creating symbolic link..."
        if [ -n "$command" ]; then
            echo "Running command: $command"
            eval "$command"
        fi
    fi
}

verified_link() {
    local source="$1"
    local target="$2"

    check_file_or_symlink "$target" "ln -s \"$source\" \"$target\""
}

CURRENT_DIR=$(pwd)
verified_link "$CURRENT_DIR/dotfiles/.ssh/config" ~/.ssh/config
verified_link "$CURRENT_DIR/dotfiles/nix/flake.nix" /etc/nix-darwin/flake.nix
verified_link "$CURRENT_DIR/dotfiles/nix/flake.lock" /etc/nix-darwin/flake.lock
verified_link "$CURRENT_DIR/dotfiles/nix/programs.nix" /etc/nix-darwin/programs.nix
verified_link "$CURRENT_DIR/dotfiles/nix/homebrew.nix" /etc/nix-darwin/homebrew.nix
