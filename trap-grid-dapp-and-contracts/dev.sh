#!/bin/bash

# Quick development script for ZK Trap Grid
set -e

echo "======================================"
echo "ZK Trap Grid - Development Helper"
echo "======================================"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."
echo ""

if ! command_exists docker; then
    echo "❌ Docker not found - Required for local Stellar network"
    exit 1
fi
echo "✅ Docker"

if ! command_exists stellar; then
    echo "❌ Stellar CLI not found"
    echo "   Install with: cargo install --locked stellar-cli"
    exit 1
fi
echo "✅ Stellar CLI"

if ! command_exists node; then
    echo "❌ Node.js not found"
    exit 1
fi
echo "✅ Node.js"

if ! command_exists cargo; then
    echo "❌ Rust/Cargo not found"
    exit 1
fi
echo "✅ Rust/Cargo"

echo ""
echo "======================================"
echo "What would you like to do?"
echo "======================================"
echo ""
echo "1) Start local Stellar network"
echo "2) Deploy contracts (requires network running)"
echo "3) Install frontend dependencies"
echo "4) Run frontend dev server"
echo "5) Build all contracts"
echo "6) Run full setup (network + deploy + frontend)"
echo "7) Exit"
echo ""
read -p "Enter your choice (1-7): " choice

case $choice in
    1)
        echo ""
        echo "Starting local Stellar network..."
        echo "Press Ctrl+C to stop when done"
        ./start-network.sh
        ;;
    2)
        echo ""
        echo "Deploying contracts..."
        ./deploy-local.sh
        ;;
    3)
        echo ""
        echo "Installing frontend dependencies..."
        cd trap-grid-frontend
        if command_exists bun; then
            bun install
        else
            npm install
        fi
        echo "✅ Dependencies installed"
        ;;
    4)
        echo ""
        echo "Starting frontend dev server..."
        cd trap-grid-frontend
        if [ ! -d "node_modules" ]; then
            echo "Installing dependencies first..."
            if command_exists bun; then
                bun install
            else
                npm install
            fi
        fi
        if command_exists bun; then
            bun dev
        else
            npm run dev
        fi
        ;;
    5)
        echo ""
        echo "Building all contracts..."
        
        echo "Building mock-game-hub..."
        cd contracts/mock-game-hub
        cargo build --target wasm32-unknown-unknown --release
        cd ../..
        
        echo "Building trap-grid..."
        cd contracts/trap-grid
        cargo build --target wasm32-unknown-unknown --release
        cd ../..
        
        echo "✅ All contracts built"
        ;;
    6)
        echo ""
        echo "Running full setup..."
        echo ""
        echo "Step 1: Building contracts..."
        cd contracts/mock-game-hub
        cargo build --target wasm32-unknown-unknown --release
        cd ../..
        cd contracts/trap-grid
        cargo build --target wasm32-unknown-unknown --release
        cd ../..
        
        echo ""
        echo "Step 2: Installing frontend dependencies..."
        cd trap-grid-frontend
        if command_exists bun; then
            bun install
        else
            npm install
        fi
        cd ..
        
        echo ""
        echo "✅ Setup complete!"
        echo ""
        echo "Next steps:"
        echo "1. In one terminal: ./dev.sh → Choose option 1 (Start network)"
        echo "2. In another terminal: ./dev.sh → Choose option 2 (Deploy contracts)"
        echo "3. Copy .contract-addresses.env to trap-grid-frontend/.env.local"
        echo "4. In another terminal: ./dev.sh → Choose option 4 (Run frontend)"
        echo ""
        ;;
    7)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
