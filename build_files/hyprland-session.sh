#!/bin/bash
# Hyprland session wrapper
# Sets up environment before starting Hyprland

# Bitwarden SSH agent socket
export SSH_AUTH_SOCK="$HOME/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock"

# Propagate to systemd and dbus for services
systemctl --user set-environment SSH_AUTH_SOCK="$SSH_AUTH_SOCK"
dbus-update-activation-environment SSH_AUTH_SOCK

exec Hyprland
