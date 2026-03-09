#!/bin/bash

set -e

BACKUP_DIR="$HOME/.config-backups"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Files and directories to manage
FILES_TO_MANAGE=(".config" ".zshrc" ".gromit-mpx.cfg" ".gromit-mpx.ini")

# Function to create backup
create_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$BACKUP_DIR/backup_$timestamp"
    mkdir -p "$backup_path"
    echo "Creating backup in $backup_path"

    for item in "${FILES_TO_MANAGE[@]}"; do
        if [ -e "$HOME/$item" ]; then
            cp -r "$HOME/$item" "$backup_path/"
            echo "Backed up $HOME/$item"
        fi
    done
    echo "Backup created: $timestamp"
}

# Function to install
install_dotfiles() {
    echo "Installing dotfiles..."
    create_backup

    for item in "${FILES_TO_MANAGE[@]}"; do
        if [ -e "$REPO_DIR/$item" ]; then
            cp -r "$REPO_DIR/$item" "$HOME/"
            echo "Installed $item"
        else
            echo "Warning: $item not found in repo"
        fi
    done
    echo "Installation complete."
}

# Function to list backups
list_backups() {
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "No backups found."
        return
    fi
    echo "Available backups:"
    ls -1 "$BACKUP_DIR" | grep '^backup_' | sed 's/backup_//' | sort -r
}

# Function to rollback
rollback() {
    local timestamp="$1"
    if [ -z "$timestamp" ]; then
        echo "Usage: $0 rollback <timestamp>"
        echo "Use '$0 list-backups' to see available timestamps."
        exit 1
    fi
    local backup_path="$BACKUP_DIR/backup_$timestamp"
    if [ ! -d "$backup_path" ]; then
        echo "Backup $timestamp not found."
        exit 1
    fi
    echo "Rolling back to $timestamp..."
    for item in "${FILES_TO_MANAGE[@]}"; do
        if [ -e "$backup_path/$item" ]; then
            cp -r "$backup_path/$item" "$HOME/"
            echo "Restored $item"
        fi
    done
    echo "Rollback complete."
}

# Main
case "$1" in
    install)
        install_dotfiles
        ;;
    rollback)
        rollback "$2"
        ;;
    list-backups)
        list_backups
        ;;
    *)
        echo "Usage: $0 {install|rollback <timestamp>|list-backups}"
        exit 1
        ;;
esac