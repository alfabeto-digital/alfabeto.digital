#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Enable nix-command and flakes
mkdir -p ~/.config/nix
cp "$SCRIPT_DIR/nix.conf" ~/.config/nix/nix.conf
echo "Nix configured."

# Create secrets.env if it doesn't exist yet
if [ ! -f "$SCRIPT_DIR/secrets.env" ]; then
  cp "$SCRIPT_DIR/secrets.env.example" "$SCRIPT_DIR/secrets.env"
  echo "Created secrets.env from example — fill in the required values before running 'nix run .#up'."
else
  echo "secrets.env already exists."
fi

echo "Done. Run: nix run .#up"
