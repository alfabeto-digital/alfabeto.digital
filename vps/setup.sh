#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create secrets.env if it doesn't exist yet
if [ ! -f "$SCRIPT_DIR/secrets.env" ]; then
  cp "$SCRIPT_DIR/secrets.env.example" "$SCRIPT_DIR/secrets.env"
  echo "Created secrets.env from example — fill in the required values before running 'podman compose up -d'."
else
  echo "secrets.env already exists."
fi

echo "Done. Run: podman compose up -d"
