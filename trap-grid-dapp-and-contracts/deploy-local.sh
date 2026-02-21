#!/bin/bash

# Deploy all contracts for trap-grid game to local Stellar network
set -e

echo "======================================"
echo "Deploying ZK Trap Grid Contracts"
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if stellar-cli is installed
if ! command -v stellar &> /dev/null; then
    echo "Error: stellar-cli not found. Please install it first."
    exit 1
fi

# Network configuration
NETWORK="standalone"
RPC_URL="http://localhost:8000/soroban/rpc"

echo ""
echo -e "${YELLOW}Step 1: Building contracts${NC}"
echo "======================================"

# Build mock-game-hub
echo "Building mock-game-hub..."
cd contracts/mock-game-hub
cargo build --target wasm32-unknown-unknown --release
cd ../..

# Build trap-grid
echo "Building trap-grid..."
cd contracts/trap-grid
cargo build --target wasm32-unknown-unknown --release
cd ../..

echo -e "${GREEN}✓ Contracts built successfully${NC}"

echo ""
echo -e "${YELLOW}Step 2: Deploying contracts${NC}"
echo "======================================"

# Create identities if they don't exist
echo "Setting up identities..."
stellar keys generate --global deployer --network standalone 2>/dev/null || true
stellar keys generate --global admin --network standalone 2>/dev/null || true

DEPLOYER=$(stellar keys address deployer)
ADMIN=$(stellar keys address admin)

echo "Deployer: $DEPLOYER"
echo "Admin: $ADMIN"

# Fund accounts (local network)
echo "Funding accounts..."
curl -s "http://localhost:8000/friendbot?addr=$DEPLOYER" > /dev/null
curl -s "http://localhost:8000/friendbot?addr=$ADMIN" > /dev/null

echo ""
echo "Deploying Mock Game Hub..."
GAME_HUB_WASM="target/wasm32-unknown-unknown/release/mock_game_hub.wasm"
GAME_HUB_ID=$(stellar contract deploy \
  --wasm $GAME_HUB_WASM \
  --source deployer \
  --network $NETWORK)

echo -e "${GREEN}✓ Game Hub deployed: $GAME_HUB_ID${NC}"

# TODO: Deploy the UltraHonk verifier contract
# This requires the compiled verifier WASM from rs-soroban-ultrahonk
echo ""
echo "Deploying UltraHonk Verifier Contract..."
VERIFIER_WASM="../rs-soroban-ultrahonk/target/wasm32-unknown-unknown/release/rs_soroban_ultrahonk.optimized.wasm"

if [ ! -f "$VERIFIER_WASM" ]; then
    echo "Warning: Optimized verifier WASM not found at $VERIFIER_WASM"
    echo "Please build and optimize it first:"
    echo "  cd ../rs-soroban-ultrahonk"
    echo "  cargo build --release --target wasm32-unknown-unknown"
    echo "  stellar contract optimize --wasm target/wasm32-unknown-unknown/release/rs_soroban_ultrahonk.wasm"
    echo ""
    echo "Using placeholder for now..."
    VERIFIER_ID="PLACEHOLDER_VERIFIER_CONTRACT"
else
    # Deploy verifier (needs VK from trap-grid circuit)
    VK_FILE="../trap-grid/target/vk"
    
    if [ ! -f "$VK_FILE" ]; then
        echo "Warning: Verification key not found at $VK_FILE"
        echo "Using placeholder verifier..."
        VERIFIER_ID="PLACEHOLDER_VERIFIER_CONTRACT"
    else
        echo "Deploying verifier with VK..."
        VERIFIER_ID=$(stellar contract deploy \
          --wasm $VERIFIER_WASM \
          --source deployer \
          --network $NETWORK \
          -- \
          --vk_bytes-file-path $VK_FILE)
        
        echo -e "${GREEN}✓ Verifier deployed and initialized: $VERIFIER_ID${NC}"
    fi
fi

echo ""
echo "Deploying Trap Grid Game Contract..."
TRAP_GRID_WASM="target/wasm32-unknown-unknown/release/trap_grid.wasm"
TRAP_GRID_ID=$(stellar contract deploy \
  --wasm $TRAP_GRID_WASM \
  --source deployer \
  --network $NETWORK \
  -- \
  --admin $ADMIN \
  --game_hub $GAME_HUB_ID \
  --verifier $VERIFIER_ID)

echo -e "${GREEN}✓ Trap Grid deployed and initialized: $TRAP_GRID_ID${NC}"

echo ""
echo "======================================"
echo -e "${GREEN}Deployment Complete!${NC}"
echo "======================================"
echo ""
echo "Contract Addresses:"
echo "-------------------"
echo "Game Hub:   $GAME_HUB_ID"
echo "Trap Grid:  $TRAP_GRID_ID"
echo "Verifier:   $VERIFIER_ID"
echo ""
echo "Save these addresses to trap-grid-frontend/.env.local:"
echo "NEXT_PUBLIC_GAME_HUB_CONTRACT=$GAME_HUB_ID"
echo "NEXT_PUBLIC_TRAP_GRID_CONTRACT=$TRAP_GRID_ID"
echo "NEXT_PUBLIC_VERIFIER_CONTRACT=$VERIFIER_ID"
echo ""

# Save to a file for easy reference
cat > .env.local << EOF
# Auto-generated contract addresses
NEXT_PUBLIC_GAME_HUB_CONTRACT=$GAME_HUB_ID
NEXT_PUBLIC_TRAP_GRID_CONTRACT=$TRAP_GRID_ID
NEXT_PUBLIC_VERIFIER_CONTRACT=$VERIFIER_ID
NEXT_PUBLIC_NETWORK_PASSPHRASE=Standalone Network ; February 2017
NEXT_PUBLIC_RPC_URL=http://localhost:8000/soroban/rpc
EOF

echo "Addresses saved to .env.local"
echo ""
