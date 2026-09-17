#!/usr/bin/env bash
# Usage: ./install.sh
# Installs nixos-config on the current machine.
set -euo pipefail

cat <<'EOF'
                 __               __
 _      ______ _/ /_  ___  __  __/ /
| | /| / / __ `/ __ \/ _ \/ / / / /
| |/ |/ / /_/ / / / /  __/ /_/ /_/
|__/|__/\__,_/_/ /_/\___/\__, (_)
                        /____/
EOF

# Replace the tracked hardware scan with this machine's own.
cp /etc/nixos/hardware-configuration.nix "$HOME/nixos-config/nixos/"

# Enable flakes and rebuild.
sudo NIX_CONFIG="experimental-features = nix-command flakes" \
  nixos-rebuild switch --flake "$HOME/nixos-config#laptop"

# Logging out to enable GNOME Desktop icons.
gnome-session-quit --logout --no-prompt
