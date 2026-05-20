#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create secrets.env if it doesn't exist yet
if [ ! -f "$SCRIPT_DIR/secrets.env" ]; then
  cp "$SCRIPT_DIR/secrets.env.template" "$SCRIPT_DIR/secrets.env"
  echo "Created secrets.env from template — fill in GERBIL_PANGOLIN_TOKEN before running 'docker compose up -d'."
else
  echo "secrets.env already exists."
fi

echo "Done. Run: docker compose up -d  (or: podman compose up -d)"
