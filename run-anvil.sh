#!/bin/bash

# Exit on error
set -e

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        echo "Error: Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to check if a port is in use
check_port() {
    if lsof -Pi :$1 -sTCP:LISTEN -t >/dev/null ; then
        echo "Error: Port $1 is already in use. Please free up the port and try again."
        exit 1
    fi
}

# Check prerequisites
check_docker
check_port 8545
check_port 8546

# Stop and remove existing container if it exists
docker stop eigenlayer-anvil 2>/dev/null || true
docker rm eigenlayer-anvil 2>/dev/null || true

# Build the custom Anvil image
echo "Building custom Anvil image..."
docker build -t eigenlayer-anvil-image -f Dockerfile.anvil .

# Start Anvil in Docker with explicit port mapping
echo "Starting Anvil node in Docker..."
docker run -d --name eigenlayer-anvil \
    -p 8545:8545 \
    -p 8546:8546 \
    eigenlayer-anvil-image

# Wait for Anvil to start and verify it's running
echo "Waiting for Anvil to start..."
for i in {1..30}; do
    if curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545 > /dev/null; then
        echo "Anvil is running!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Error: Failed to start Anvil. Please check Docker logs with: docker logs eigenlayer-anvil"
        exit 1
    fi
    sleep 1
done
