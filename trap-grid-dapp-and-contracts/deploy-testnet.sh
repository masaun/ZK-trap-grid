#!/bin/bash

# Deploy all contracts for trap-grid game to Stellar Testnet
# Uses the trap-grid-position-movement circuit for on-chain proof verification
set -e

echo "======================================"
echo "Deploying to Stellar Testnet"
echo "ZK Trap Grid with Position Movement"
echo "======================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if stellar-cli is installed
if ! command -v stellar &> /dev/null; then
    echo -e "${RED}Error: stellar-cli not found. Please install it first.${NC}"
    exit 1
fi

# Network configuration
NETWORK="testnet"

# Circuit paths
CIRCUIT_DIR="../trap-grid/trap-grid-position-movement"
CIRCUIT_TARGET="$CIRCUIT_DIR/target"

# Load environment variables for testnet account
if [ -f ".env" ]; then
    echo "Loading .env file..."
    source .env
fi

# Check for source account
SOURCE_ACCOUNT="${STELLAR_SOURCE_ACCOUNT:-}"
if [ -z "$SOURCE_ACCOUNT" ]; then
    echo -e "${RED}Error: STELLAR_SOURCE_ACCOUNT not set${NC}"
    echo ""
    echo "Please set your testnet identity name:"
    echo "  export STELLAR_SOURCE_ACCOUNT=your-testnet-identity"
    echo ""
    echo "To create and fund a testnet account:"
    echo "  1. stellar keys generate your-testnet-identity"
    echo "  2. stellar keys fund your-testnet-identity --network testnet"
    exit 1
fi

echo -e "${GREEN}Using source account: $SOURCE_ACCOUNT${NC}"

echo ""
echo -e "${YELLOW}Step 0: Building Position Movement Circuit${NC}"
echo "======================================"

if [ ! -d "$CIRCUIT_DIR" ]; then
    echo -e "${RED}Error: Circuit directory not found at $CIRCUIT_DIR${NC}"
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
  -b ./target/trap_grid_position_movement.json \
  -o ./target/vk

echo -e "${GREEN}✓ Circuit built successfully${NC}"

# Return to deployment directory
cd - > /dev/null

echo ""
echo -e "${YELLOW}Step 1: Building rs-soroban-ultrahonk verifier${NC}"
echo "======================================"

cd "../rs-soroban-ultrahonk"

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
echo -e "${YELLOW}Step 3: Deploying contracts to Stellar Testnet${NC}"
echo "======================================"

echo ""
echo "Deploying Mock Game Hub..."
GAME_HUB_WASM="target/wasm32-unknown-unknown/release/mock_game_hub.wasm"
GAME_HUB_ID=$(stellar contract deploy \
  --wasm $GAME_HUB_WASM \
  --source-account $SOURCE_ACCOUNT \
  --network $NETWORK | tail -n1)

echo -e "${GREEN}✓ Game Hub deployed: $GAME_HUB_ID${NC}"

echo ""
echo "Deploying UltraHonk Verifier Contract with Position Movement VK..."
VERIFIER_WASM="../rs-soroban-ultrahonk/target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm"
VK_FILE="$CIRCUIT_TARGET/vk"

if [ ! -f "$VERIFIER_WASM" ]; then
    echo -e "${RED}Error: Verifier WASM not found at $VERIFIER_WASM${NC}"
    echo "Please build it first: cd ../rs-soroban-ultrahonk && stellar contract build"
    exit 1
fi

if [ ! -f "$VK_FILE" ]; then
    echo -e "${RED}Error: Verification key not found at $VK_FILE${NC}"
    echo "Please build the circuit first (see Step 0)"
    exit 1
fi

echo "Deploying verifier (this may take a moment)..."
VERIFIER_ID=$(stellar contract deploy \
  --wasm $VERIFIER_WASM \
  --source-account $SOURCE_ACCOUNT \
  --network $NETWORK \
  -- \
  --vk_bytes-file-path $VK_FILE | tail -n1)

echo -e "${GREEN}✓ Verifier deployed and initialized: $VERIFIER_ID${NC}"

echo ""
echo "Deploying Trap Grid Game Contract..."
TRAP_GRID_WASM="target/wasm32-unknown-unknown/release/trap_grid.wasm"
TRAP_GRID_ID=$(stellar contract deploy \
  --wasm $TRAP_GRID_WASM \
  --source-account $SOURCE_ACCOUNT \
  --network $NETWORK | tail -n1)

echo -e "${GREEN}✓ Trap Grid deployed: $TRAP_GRID_ID${NC}"

# Get admin address
ADMIN=$(stellar keys address $SOURCE_ACCOUNT)

# Initialize the contract
echo "Initializing Trap Grid contract..."
stellar contract invoke \
  --id $TRAP_GRID_ID \
  --source-account $SOURCE_ACCOUNT \
  --network $NETWORK \
  --send yes \
  -- \
  __constructor \
  --admin $ADMIN \
  --game_hub $GAME_HUB_ID \
  --verifier $VERIFIER_ID > /dev/null

echo -e "${GREEN}✓ Trap Grid initialized${NC}"

echo ""
echo "════════════════════════════════════════════════════════════"
echo -e "${GREEN}✅ Deployment to Stellar Testnet Complete!${NC}"
echo "════════════════════════════════════════════════════════════"
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
echo "🔗 View on Stellar Expert:"
echo "   Game Hub:   https://stellar.expert/explorer/testnet/contract/$GAME_HUB_ID"
echo "   Trap Grid:  https://stellar.expert/explorer/testnet/contract/$TRAP_GRID_ID"
echo "   Verifier:   https://stellar.expert/explorer/testnet/contract/$VERIFIER_ID"
echo ""
echo "Save these addresses to app/.env.local:"
echo "NEXT_PUBLIC_GAME_HUB_CONTRACT=$GAME_HUB_ID"
echo "NEXT_PUBLIC_TRAP_GRID_CONTRACT=$TRAP_GRID_ID"
echo "NEXT_PUBLIC_VERIFIER_CONTRACT=$VERIFIER_ID"
echo ""

# Save to a file for easy reference
cat > app/.env.local << EOF
# Auto-generated contract addresses - Stellar Testnet
NEXT_PUBLIC_GAME_HUB_CONTRACT=$GAME_HUB_ID
NEXT_PUBLIC_TRAP_GRID_CONTRACT=$TRAP_GRID_ID
NEXT_PUBLIC_VERIFIER_CONTRACT=$VERIFIER_ID
NEXT_PUBLIC_NETWORK_PASSPHRASE=Test SDF Network ; September 2015
NEXT_PUBLIC_RPC_URL=https://soroban-testnet.stellar.org
EOF

echo "Addresses saved to app/.env.local"
echo ""
echo "Next steps:"
echo "1. Copy circuit artifact: cp $CIRCUIT_TARGET/trap_grid_position_movement.json app/public/circuits/"
echo "2. Start the frontend: cd app && npm run dev"
echo "3. Test on-chain verification!"
echo ""
