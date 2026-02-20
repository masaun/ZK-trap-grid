#!/bin/bash

# Alternative: Start Stellar network using stellar CLI
set -e

echo "======================================"
echo "Starting Stellar Network (CLI Method)"
echo "======================================"

# Check if stellar CLI is installed
if ! command -v stellar &> /dev/null; then
    echo "Error: stellar CLI not found."
    echo "Install with: cargo install --locked stellar-cli"
    exit 1
fi

echo ""
echo "Starting Stellar network using stellar CLI..."
echo "This will run a local Stellar network on:"
echo "  - RPC Server: http://localhost:8000/soroban/rpc"
echo "  - Horizon API: http://localhost:8000"
echo ""

# Start the network using stellar CLI
# This will download and manage the Docker container automatically
stellar network container start standalone

echo ""
echo "Network is running!"
echo ""
echo "To view logs:"
echo "  stellar network container logs standalone"
echo ""
echo "To stop:"
echo "  stellar network container stop standalone"
echo ""
echo "Press Ctrl+C to stop this script (network will keep running)"
echo ""

# Keep script running and show logs
stellar network container logs standalone -f
