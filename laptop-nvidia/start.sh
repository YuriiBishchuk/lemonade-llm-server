#!/bin/bash
# ============================================================
# Lemonade Server — Laptop NVIDIA (Bazzite)
# ============================================================
# NOTE: Uses host Podman via CONTAINER_HOST socket.
# Run this inside Toolbx — Podman talks to the host daemon.
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ensure we're using the host Podman (not Toolbx's broken nested Podman)
export CONTAINER_HOST=unix:///run/user/1000/podman/podman.sock

# Create persistent volume directories
mkdir -p lemonade-cache huggingface-cache llama-data shader-cache

echo "🚀 Starting Lemonade Server (NVIDIA — True CUDA Mode)..."
podman-compose up --build -d --force-recreate

echo "⏳ Waiting for server to initialize..."
sleep 15

# Pull the model if not already cached
echo "📦 Pulling model (Q4_0 variant for optimal inference speed)..."
podman exec lemonade-nvidia /opt/lemonade/lemonade pull unsloth/gemma-4-E2B-it-GGUF:Q4_0 || true

echo ""
echo "✅ Lemonade Server is running!"
echo "   API:  http://localhost:13306"
