#!/bin/bash

# Lemonade Unified Server Manager
# Optimized for MicroOS / Podman / Docker

set -e

GITHUB_API="https://api.github.com/repos/YuriiBishchuk/lemonade-llm-server/commits/main"
GITHUB_TAR="https://github.com/YuriiBishchuk/lemonade-llm-server/archive/refs/heads/main.tar.gz"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🍋 Lemonade Unified Server Manager${NC}"

# 1. Check Dependencies
check_dependencies() {
    for cmd in curl tar docker; do
        if ! command -v $cmd &> /dev/null; then
            echo -e "${RED}Error: $cmd is not installed.${NC}"
            exit 1
        fi
    done
}

# 2. Setup Environment
init_env() {
    if [ ! -f .env ]; then
        echo -e "${BLUE}First-time setup detected. Configuring .env...${NC}"
        
        read -p "Enter Telegram Bot Token: " TG_TOKEN
        read -p "Enter Telegram Chat ID: " TG_CHAT_ID
        
        cat > .env <<EOF
TELEGRAM_BOT_TOKEN=$TG_TOKEN
TELEGRAM_CHAT_ID=$TG_CHAT_ID
OPENCLAW_MODEL=user.gemma-4-E2B-it-GGUF-Q4_K_M
OPENCLAW_API_KEY=lemonade-local
OPENCLAW_TOKEN=lemonade-token
EOF
        echo -e "${GREEN}✅ .env file created.${NC}"
    fi

    # Fix permissions before writing to ensure we have access
    sudo chown -R $USER:$USER config workspace qdrant_data 2>/dev/null || true
    sudo chmod -R 777 config workspace qdrant_data 2>/dev/null || true

    # Always ensure OpenClaw JSON config is correct
    mkdir -p config
    cat > config/openclaw.json <<EOF
{
  "gateway": {
    "controlUi": {
      "allowedOrigins": ["*"]
    },
    "auth": {
      "token": "lemonade-token"
    },
    "devicePairing": {
      "enabled": false
    }
  },
  "channels": {
    "telegram": {
      "enabled": true
    }
  },
  "meta": {
    "lastTouchedVersion": "2026.4.29",
    "lastTouchedAt": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  }
}
EOF
    # Set permissions back for the container user (1000) and make it world-writable
    sudo chown -R 1000:1000 config workspace qdrant_data 2>/dev/null || true
    sudo chmod -R 777 config workspace qdrant_data 2>/dev/null || true
    
    echo -e "${GREEN}✅ OpenClaw configuration verified.${NC}"
}

# 3. Update Code from GitHub
update_code() {
    echo -e "${BLUE}Checking for updates...${NC}"
    
    LATEST_SHA=$(curl -s $GITHUB_API | grep '"sha":' | head -n 1 | cut -d '"' -f 4)
    
    if [ -z "$LATEST_SHA" ]; then
        echo -e "${RED}Warning: Could not check for updates.${NC}"
        return
    fi

    CURRENT_SHA=""
    if [ -f version.txt ]; then
        CURRENT_SHA=$(cat version.txt)
    fi

    if [ "$LATEST_SHA" != "$CURRENT_SHA" ]; then
        echo -e "${BLUE}New version found ($LATEST_SHA). Downloading...${NC}"
        
        curl -L $GITHUB_TAR -o update.tar.gz
        mkdir -p update_tmp
        tar -xzf update.tar.gz -C update_tmp --strip-components=1
        
        # Fix permissions before update to ensure we can overwrite files
        echo -e "${BLUE}Fixing permissions for update...${NC}"
        sudo chown -R $USER:$USER . 2>/dev/null || true
        
        # Copy content from the 'server' folder of the repo to current folder
        cp -rf update_tmp/server/* .
        
        echo "$LATEST_SHA" > version.txt
        rm -rf update.tar.gz update_tmp
        echo -e "${GREEN}✅ Update applied.${NC}"
    else
        echo -e "${GREEN}✅ You are on the latest version.${NC}"
    fi
}

# 4. Deploy Containers
deploy() {
    echo -e "${BLUE}Deploying containers...${NC}"
    
    docker network inspect proxy-network >/dev/null 2>&1 || \
        docker network create proxy-network

    # Detect compose command
    COMPOSE_CMD="docker compose"
    if ! command -v docker-compose &> /dev/null && ! docker help compose &> /dev/null; then
        if command -v podman-compose &> /dev/null; then
            COMPOSE_CMD="podman-compose"
        fi
    fi

    echo -e "${BLUE}Starting Lemonade Model...${NC}"
    $COMPOSE_CMD -f docker-compose.model.yml up -d --pull always

    echo -e "${BLUE}Starting OpenClaw...${NC}"
    $COMPOSE_CMD -f docker-compose.openclaw.yml up -d --pull always
    
    echo -e "${GREEN}🚀 All services are up and running!${NC}"
    echo -e "Web UI: http://$(hostname -I | awk '{print $1}'):3000"
}

# --- Execution ---
check_dependencies
init_env
update_code
deploy
