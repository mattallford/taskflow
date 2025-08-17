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
POSTGRES_IMAGE="postgres:15"
API_IMAGE="taskflow-api:latest"

# Database configuration
DB_NAME="taskflowdb"
DB_USER="taskflow"
DB_PASSWORD="taskflow123"
DB_PORT="5432"
API_PORT="8080"

echo -e "${GREEN}🚀 Starting TaskFlow containerized environment${NC}"

# Function to check if container exists
container_exists() {
    docker ps -a --format '{{.Names}}' | grep -q "^$1$"
}

# Function to check if container is running
container_running() {
    docker ps --format '{{.Names}}' | grep -q "^$1$"
}

# Function to wait for PostgreSQL to be ready
wait_for_postgres() {
    echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker exec $POSTGRES_CONTAINER pg_isready -U $DB_USER -d $DB_NAME -q; then
            echo -e "${GREEN}✅ PostgreSQL is ready!${NC}"
            return 0
        fi
        
        echo "Attempt $attempt/$max_attempts: PostgreSQL not ready yet..."
        sleep 2
        ((attempt++))
    done
    
    echo -e "${RED}❌ PostgreSQL failed to become ready after $max_attempts attempts${NC}"
    return 1
}

# Create Docker network if it doesn't exist
if ! docker network ls | grep -q $NETWORK_NAME; then
    echo -e "${YELLOW}📡 Creating Docker network: $NETWORK_NAME${NC}"
    docker network create $NETWORK_NAME
else
    echo -e "${GREEN}📡 Docker network $NETWORK_NAME already exists${NC}"
fi

# Stop and remove existing containers if they exist
for container in $API_CONTAINER $POSTGRES_CONTAINER; do
    if container_running $container; then
        echo -e "${YELLOW}🛑 Stopping running container: $container${NC}"
        docker stop $container
    fi
    
    if container_exists $container; then
        echo -e "${YELLOW}🗑️  Removing existing container: $container${NC}"
        docker rm $container
    fi
done

# Start PostgreSQL container
echo -e "${YELLOW}🐘 Starting PostgreSQL container...${NC}"
docker run -d \
    --name $POSTGRES_CONTAINER \
    --network $NETWORK_NAME \
    -e POSTGRES_DB=$DB_NAME \
    -e POSTGRES_USER=$DB_USER \
    -e POSTGRES_PASSWORD=$DB_PASSWORD \
    -p $DB_PORT:5432 \
    -v taskflow_db_data:/var/lib/postgresql/data \
    $POSTGRES_IMAGE

# Wait for PostgreSQL to be ready
if ! wait_for_postgres; then
    echo -e "${RED}❌ Failed to start PostgreSQL${NC}"
    exit 1
fi

# Start API container
echo -e "${YELLOW}🌐 Starting TaskFlow API container...${NC}"
docker run -d \
    --name $API_CONTAINER \
    --network $NETWORK_NAME \
    -p $API_PORT:8080 \
    -e ASPNETCORE_ENVIRONMENT=Production \
    -e ConnectionStrings__DefaultConnection="Host=$POSTGRES_CONTAINER;Database=$DB_NAME;Username=$DB_USER;Password=$DB_PASSWORD" \
    $API_IMAGE

# Wait a moment for the API to start
echo -e "${YELLOW}⏳ Waiting for API to start...${NC}"
sleep 5

# Check if API is responding
echo -e "${YELLOW}🔍 Checking API health...${NC}"
max_attempts=30
attempt=1

while [ $attempt -le $max_attempts ]; do
    if curl -f -s http://localhost:$API_PORT/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API is healthy and responding!${NC}"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        echo -e "${RED}❌ API failed to respond after $max_attempts attempts${NC}"
        echo -e "${YELLOW}📋 Checking API container logs:${NC}"
        docker logs $API_CONTAINER --tail 20
        exit 1
    fi
    
    echo "Attempt $attempt/$max_attempts: API not ready yet..."
    sleep 2
    ((attempt++))
done

echo -e "${GREEN}🎉 TaskFlow environment is running successfully!${NC}"
echo ""
echo -e "${GREEN}📋 Environment Details:${NC}"
echo "  🌐 API URL: http://localhost:$API_PORT"
echo "  🏥 Health Check: http://localhost:$API_PORT/health"
echo "  📚 API Docs: http://localhost:$API_PORT/swagger (if available)"
echo "  🐘 PostgreSQL: localhost:$DB_PORT"
echo ""
echo -e "${GREEN}🔧 Management Commands:${NC}"
echo "  📊 View API logs: docker logs $API_CONTAINER -f"
echo "  📊 View DB logs: docker logs $POSTGRES_CONTAINER -f"
echo "  🛑 Stop environment: docker stop $API_CONTAINER $POSTGRES_CONTAINER"
echo "  🗑️  Remove containers: docker rm $API_CONTAINER $POSTGRES_CONTAINER"
echo "  🧹 Clean up everything: docker rm $API_CONTAINER $POSTGRES_CONTAINER && docker network rm $NETWORK_NAME && docker volume rm taskflow_db_data"
echo ""
echo -e "${GREEN}🧪 Test the API:${NC}"
echo "  curl http://localhost:$API_PORT/health"
echo "  curl http://localhost:$API_PORT/api/tasks"