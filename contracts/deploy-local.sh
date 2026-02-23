#!/bin/bash

# Deploy all contracts for trap-grid game to local Stellar network
# Uses the trap-grid-position-movement circuit for on-chain proof verification
set -e

echo "======================================"
echo "Deploying ZK Trap Grid Contracts"
echo "with Position Movement Circuit"
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

# Note: For local development, we use a mock game hub.
# For Stellar Testnet deployment, use deploy-testnet.sh which connects to the
# official hackathon game hub: CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG

# Load environment variables for account configuration
if [ -f ".env" ]; then
    echo "Loading .env file..."
    source .env
fi

# Circuit paths
CIRCUIT_DIR="../circuits/position-movement"
CIRCUIT_TARGET="$CIRCUIT_DIR/target"

echo ""
echo -e "${YELLOW}Step 0: Building Position Movement Circuit${NC}"
echo "======================================"

if [ ! -d "$CIRCUIT_DIR" ]; then
    echo "Error: Circuit directory not found at $CIRCUIT_DIR"
    exit 1
fi

cd "$CIRCUIT_DIR"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing circuit dependencies..."
    npm install
fi

# Compile and build circuit artifacts
echo "Compiling Noir circuit..."
nargo compile

echo "Generating verification key..."
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"
node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/position_movement.json \
  -o ./target/vk

echo -e "${GREEN}✓ Circuit built successfully${NC}"

# Return to deployment directory
cd - > /dev/null

echo ""
echo -e "${YELLOW}Step 1: Building rs-soroban-ultrahonk verifier${NC}"
echo "======================================"

cd "../circuits/position-movement/rs-soroban-ultrahonk"

echo "Building verifier contract..."
stellar contract build

echo -e "${GREEN}✓ Verifier contract built${NC}"

cd - > /dev/null

echo ""
echo -e "${YELLOW}Step 2: Building game contracts${NC}"
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

echo -e "${GREEN}✓ Game contracts built successfully${NC}"

echo ""
echo -e "${YELLOW}Step 3: Deploying contracts to local network${NC}"
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

echo ""
echo "Deploying UltraHonk Verifier Contract with Position Movement VK..."
VERIFIER_WASM="../circuits/position-movement/rs-soroban-ultrahonk/target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm"
VK_FILE="$CIRCUIT_TARGET/vk"

if [ ! -f "$VERIFIER_WASM" ]; then
    echo "Error: Verifier WASM not found at $VERIFIER_WASM"
    echo "Please build it first: cd ../circuits/position-movement/rs-soroban-ultrahonk && stellar contract build"
    exit 1
fi

if [ ! -f "$VK_FILE" ]; then
    echo "Error: Verification key not found at $VK_FILE"
    echo "Please build the circuit first (see Step 0)"
    exit 1
fi

VERIFIER_ID=$(stellar contract deploy \
  --wasm $VERIFIER_WASM \
  --source deployer \
  --network $NETWORK \
  -- \
  --vk_bytes-file-path $VK_FILE)

echo -e "${GREEN}✓ Verifier deployed and initialized: $VERIFIER_ID${NC}"

echo ""
echo "Deploying Trap Grid Game Contract..."
TRAP_GRID_WASM="target/wasm32-unknown-unknown/release/trap_grid.wasm"
TRAP_GRID_ID=$(stellar contract deploy \
  --wasm $TRAP_GRID_WASM \
  --source deployer \
  --network $NETWORK)

# Initialize the contract
echo "Initializing Trap Grid contract..."
stellar contract invoke \
  --id $TRAP_GRID_ID \
  --source deployer \
  --network $NETWORK \
  -- \
  __constructor \
  --admin $ADMIN \
  --game_hub $GAME_HUB_ID \
  --verifier $VERIFIER_ID

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
echo "Circuit: trap-grid-position-movement"
echo "VK Location: $VK_FILE"
echo ""
echo "Save these addresses to app/.env.local:"
echo "NEXT_PUBLIC_GAME_HUB_CONTRACT=$GAME_HUB_ID"
echo "NEXT_PUBLIC_TRAP_GRID_CONTRACT=$TRAP_GRID_ID"
echo "NEXT_PUBLIC_VERIFIER_CONTRACT=$VERIFIER_ID"
echo ""

# Save to a file for easy reference
cat > app/.env.local << EOF
# Auto-generated contract addresses - Local Network
NEXT_PUBLIC_GAME_HUB_CONTRACT=$GAME_HUB_ID
NEXT_PUBLIC_TRAP_GRID_CONTRACT=$TRAP_GRID_ID
NEXT_PUBLIC_VERIFIER_CONTRACT=$VERIFIER_ID
NEXT_PUBLIC_NETWORK_PASSPHRASE=Standalone Network ; February 2017
NEXT_PUBLIC_RPC_URL=http://localhost:8000/soroban/rpc
EOF

echo "Addresses saved to app/.env.local"
echo ""
echo "Next steps:"
echo "1. Copy circuit artifact: cp $CIRCUIT_TARGET/position_movement.json ../app/public/circuits/trap_grid_position_movement.json"
echo "2. Start the frontend: cd ../app && npm run dev"
echo ""
