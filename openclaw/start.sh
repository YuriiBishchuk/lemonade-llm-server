#!/bin/bash
# ============================================================
# OpenClaw — Autonomous AI Agent (Connected to Lemonade)
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Create workspace, config and vector store directories
mkdir -p workspace config qdrant_data

echo "🚀 Starting OpenClaw Agent..."
echo "🔗 Connecting to Lemonade Server at http://lemonade:13305"

podman compose up -d

echo ""
echo "✅ OpenClaw is running!"
echo "   Web UI: http://localhost:3000"
echo "   Workspace: $SCRIPT_DIR/workspace"
