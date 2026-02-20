#!/bin/bash

# Start local Stellar network for ZK Trap Grid development
set -e

echo "======================================"
echo "Starting Local Stellar Network"
echo "======================================"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found. Please install Docker first."
    exit 1
fi

# Check if stellar-cli is installed
if ! command -v stellar &> /dev/null; then
    echo "Error: stellar-cli not found. Please install it first."
    echo "Installation: cargo install --locked stellar-cli"
    exit 1
fi

echo ""
echo "Starting Stellar quickstart container..."
echo "This will run a local Stellar network on:"
echo "  - RPC Server: http://localhost:8000/soroban/rpc"
echo "  - Horizon API: http://localhost:8000"
echo ""

# Check if stellar container is already running
if docker ps | grep -q stellar; then
    echo "Stellar container is already running."
    echo "To stop it, run: docker stop stellar"
    exit 0
fi

# Run Stellar quickstart with Soroban
# Using latest soroban-dev tag instead of specific SHA
docker run --rm -it \
  -p 8000:8000 \
  --name stellar \
  stellar/quickstart:testing \
  --standalone \
  --enable-soroban-rpc

echo ""
echo "Network stopped."
