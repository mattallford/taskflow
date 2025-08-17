#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NETWORK_NAME="taskflow-network"
POSTGRES_CONTAINER="taskflow-postgres"
API_CONTAINER="taskflow-api"
VOLUME_NAME="taskflow_db_data"

echo -e "${YELLOW}🧹 Cleaning up TaskFlow containerized environment${NC}"

# Function to check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^$1$" 2>/dev/null || false
}

# Function to check if network exists
network_exists() {
    docker network ls --format '{{.Name}}' | grep -q "^$1$" 2>/dev/null || false
}

# Function to check if volume exists
volume_exists() {
    docker volume ls --format '{{.Name}}' | grep -q "^$1$" 2>/dev/null || false
}

# Stop and remove containers
for container in $API_CONTAINER $POSTGRES_CONTAINER; do
    if container_exists $container; then
        echo -e "${YELLOW}🛑 Stopping and removing container: $container${NC}"
        docker stop $container 2>/dev/null || true
        docker rm $container 2>/dev/null || true
        echo -e "${GREEN}✅ Removed container: $container${NC}"
    else
        echo -e "${GREEN}✅ Container $container does not exist${NC}"
    fi
done

# Remove network
if network_exists $NETWORK_NAME; then
    echo -e "${YELLOW}📡 Removing Docker network: $NETWORK_NAME${NC}"
    docker network rm $NETWORK_NAME 2>/dev/null || true
    echo -e "${GREEN}✅ Removed network: $NETWORK_NAME${NC}"
else
    echo -e "${GREEN}✅ Network $NETWORK_NAME does not exist${NC}"
fi

# Ask about volume removal
if volume_exists $VOLUME_NAME; then
    echo -e "${YELLOW}⚠️  Database volume $VOLUME_NAME exists${NC}"
    read -p "Do you want to remove the database volume? This will delete all data! (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🗑️  Removing database volume: $VOLUME_NAME${NC}"
        docker volume rm $VOLUME_NAME 2>/dev/null || true
        echo -e "${GREEN}✅ Removed volume: $VOLUME_NAME${NC}"
    else
        echo -e "${GREEN}✅ Database volume preserved${NC}"
    fi
else
    echo -e "${GREEN}✅ Volume $VOLUME_NAME does not exist${NC}"
fi

# Remove dangling images (optional)
echo -e "${YELLOW}🧹 Cleaning up dangling images...${NC}"
docker image prune -f > /dev/null 2>&1 || true

echo -e "${GREEN}🎉 Cleanup completed!${NC}"
echo ""
echo -e "${GREEN}📋 Cleanup Summary:${NC}"
echo "  ✅ Containers stopped and removed"
echo "  ✅ Network removed (if existed)"
echo "  ✅ Dangling images cleaned"
echo ""
echo -e "${YELLOW}ℹ️  To start the environment again, run:${NC}"
echo "  ./deploy/docker/run.sh"