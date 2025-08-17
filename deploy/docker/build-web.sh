#!/bin/bash
set -e

echo "Building TaskFlow Web Frontend Docker image..."

# Build from solution root
cd "$(dirname "$0")/../.."

# Build the Web frontend container
docker build -f deploy/docker/Dockerfile.web -t taskflow-web:latest .

echo "✅ TaskFlow Web Frontend image built successfully!"
echo "Image: taskflow-web:latest"

# Show image size
docker images taskflow-web:latest