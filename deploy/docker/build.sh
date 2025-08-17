#!/bin/bash
set -e

echo "Building TaskFlow API Docker image..."

# Build from solution root
cd "$(dirname "$0")/../.."

# Build the API container
docker build -f deploy/docker/Dockerfile.api -t taskflow-api:latest .

echo "✅ TaskFlow API image built successfully!"
echo "Image: taskflow-api:latest"

# Show image size
docker images taskflow-api:latest