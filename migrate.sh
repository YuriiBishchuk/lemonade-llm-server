#!/bin/bash

# ============================================================
# Lemonade Migration Script
# ============================================================

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🚚 Lemonade Migration Tool${NC}"

# 1. Check for running containers and stop them
echo -e "${BLUE}Stopping any running Lemonade/OpenClaw services...${NC}"
CONTAINERS=$(docker ps -q --filter "name=lemonade" --filter "name=openclaw" --filter "name=qdrant" --filter "name=searxng")

if [ ! -z "$CONTAINERS" ]; then
    docker stop $CONTAINERS
    echo -e "${GREEN}✅ Services stopped.${NC}"
else
    echo -e "No active services found."
fi

# 2. Ask for new destination
read -p "Enter the new destination path (absolute path): " NEW_PATH

if [ -z "$NEW_PATH" ]; then
    echo -e "${RED}Error: Path cannot be empty.${NC}"
    exit 1
fi

# Create directory if not exists
mkdir -p "$NEW_PATH"

# 3. Move files
CURRENT_DIR=$(pwd)
echo -e "${BLUE}Moving project from $CURRENT_DIR to $NEW_PATH...${NC}"

# We use 'cp -a' and then 'rm' to avoid issues with moving the script itself while running
cp -a . "$NEW_PATH/"

# 4. Switch to new location
cd "$NEW_PATH"

# 5. Ensure manage.sh exists in server directory
if [ ! -f "server/manage.sh" ]; then
    echo -e "${BLUE}manage.sh not found in server directory. Downloading bootstrap...${NC}"
    mkdir -p server
    curl -L https://raw.githubusercontent.com/YuriiBishchuk/lemonade-llm-server/main/server/manage.sh -o server/manage.sh
    chmod +x server/manage.sh
fi

# 6. Run the manager
echo -e "${GREEN}✅ Migration complete. Starting services in new location...${NC}"
cd server
./manage.sh

# Optional: Cleanup old directory?
# The user might want to keep it as backup, so I won't delete it automatically, 
# but I'll print a message.
echo -e "\n${BLUE}Note: The old files at $CURRENT_DIR are still there. You can delete them manually if everything works.${NC}"
