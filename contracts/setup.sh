#!/bin/bash

# Setup script for the trap-grid dapp frontend
# Copies circuit artifacts and prepares the environment

set -e

echo "======================================"
echo "Setting up Trap Grid Frontend"
echo "======================================"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

CIRCUIT_DIR="../circuits/position-movement"
CIRCUIT_TARGET="$CIRCUIT_DIR/target"
CIRCUIT_FILE="$CIRCUIT_TARGET/position_movement.json"
PUBLIC_CIRCUITS="./app/public/circuits"

echo ""
echo -e "${YELLOW}Step 1: Checking circuit artifact${NC}"

if [ ! -f "$CIRCUIT_FILE" ]; then
    echo -e "${RED}Circuit artifact not found!${NC}"
    echo "Building the circuit first..."
    
    cd "$CIRCUIT_DIR"
    
    if [ ! -d "node_modules" ]; then
        echo "Installing circuit dependencies..."
        npm install
    fi
    
    echo "Compiling circuit..."
    nargo compile
    
    cd - > /dev/null
fi

if [ ! -f "$CIRCUIT_FILE" ]; then
    echo -e "${RED}Error: Failed to build circuit artifact${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Circuit artifact found${NC}"

echo ""
echo -e "${YELLOW}Step 2: Creating circuits directory${NC}"

mkdir -p "$PUBLIC_CIRCUITS"

echo ""
echo -e "${YELLOW}Step 3: Copying circuit artifact${NC}"

cp "$CIRCUIT_FILE" "$PUBLIC_CIRCUITS/trap_grid_position_movement.json"
echo -e "${GREEN}✓ Copied to $PUBLIC_CIRCUITS/trap_grid_position_movement.json${NC}"

echo ""
echo -e "${YELLOW}Step 4: Checking frontend dependencies${NC}"

cd app

if [ ! -d "node_modules" ]; then
    echo "Installing frontend dependencies..."
    npm install
else
    echo "Dependencies already installed"
fi

echo ""
echo -e "${YELLOW}Step 5: Checking environment configuration${NC}"

if [ ! -f ".env.local" ]; then
    echo -e "${YELLOW}Warning: .env.local not found${NC}"
    echo "Creating template..."
    
    cat > .env.local << 'EOF'
# Stellar Contract Addresses
# Replace these with your deployed contract addresses

# For Local Network:
# NEXT_PUBLIC_GAME_HUB_CONTRACT=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# NEXT_PUBLIC_TRAP_GRID_CONTRACT=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# NEXT_PUBLIC_VERIFIER_CONTRACT=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# NEXT_PUBLIC_NETWORK_PASSPHRASE=Standalone Network ; February 2017
# NEXT_PUBLIC_RPC_URL=http://localhost:8000/soroban/rpc

# For Stellar Testnet:
# NEXT_PUBLIC_GAME_HUB_CONTRACT=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# NEXT_PUBLIC_TRAP_GRID_CONTRACT=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# NEXT_PUBLIC_VERIFIER_CONTRACT=CXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
# NEXT_PUBLIC_NETWORK_PASSPHRASE=Test SDF Network ; September 2015
# NEXT_PUBLIC_RPC_URL=https://soroban-testnet.stellar.org

# TODO: Deploy contracts and update these values
EOF
    
    echo -e "${YELLOW}Created .env.local template${NC}"
    echo "Run ./deploy-local.sh or ./deploy-testnet.sh to deploy contracts and auto-populate"
else
    echo -e "${GREEN}✓ .env.local exists${NC}"
fi

cd ..

echo ""
echo "======================================"
echo -e "${GREEN}✅ Setup Complete!${NC}"
echo "======================================"
echo ""
echo "Files created/updated:"
echo "  - app/public/circuits/trap_grid_position_movement.json"
echo "  - app/.env.local (if not exists)"
echo ""
echo "Next steps:"
echo "1. Deploy contracts:"
echo "   ./deploy-local.sh      (for local network)"
echo "   ./deploy-testnet.sh    (for Stellar testnet)"
echo ""
echo "2. Start the frontend:"
echo "   cd app"
echo "   npm run dev"
echo ""
echo "3. Open http://localhost:3000"
echo ""
