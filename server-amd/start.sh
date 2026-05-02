#!/bin/bash
# ============================================================
# Lemonade Server — AMD Ryzen Vega 11 (server-amd)
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create persistent volume directories
mkdir -p lemonade-cache huggingface-cache llama-data shader-cache shader-cache-radv

echo "🚀 Starting Lemonade Server (AMD Vega 11 — Extreme Vulkan Mode)..."
podman compose up -d

echo "⏳ Waiting for server to initialize (first run compiles GPL shaders)..."
sleep 10

# Pull the model if not already cached
echo "📦 Pulling model (Q4_0 variant for optimal inference speed)..."
podman exec lemonade /opt/lemonade/lemonade pull unsloth/gemma-4-E2B-it-GGUF:Q4_0 || true

echo ""
echo "✅ Lemonade Server is running!"
echo "   API:  http://localhost:13305"
echo "   Note: First request triggers shader compilation — subsequent runs are instant."
