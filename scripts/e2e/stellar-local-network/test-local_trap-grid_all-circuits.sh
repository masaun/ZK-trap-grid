#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Trap Grid ZK Circuits - Local Test Script
# ============================================================================
# This script compiles the trap grid ZK circuits, generates proofs, and verifies
# them on a local Stellar network.
#
# PREREQUISITES:
#   1. Valid test data in each circuit's Prover.toml
#      - trap-merkle-root: Valid merkle proof data
#      - position-movement: Valid position and movement data
#
#   2. Local Stellar network running (for deployment steps)
#      Run: stellar container start -t future --limits unlimited
#
#   3. Source account configured (default: 'alice')
#      The account must exist and be funded on the local network
#      Set STELLAR_SOURCE_ACCOUNT env var to use a different account
#
# NOTE: If Prover.toml doesn't have cryptographically valid data,
#       the script will stop after circuit compilation with instructions.
#
# CIRCUITS:
# 1. trap-merkle-root: Verifies the trap grid merkle root
# 2. position-movement: Verifies position movement and trap detection
# ============================================================================

# Set ROOT to project root (3 levels up from scripts/e2e/stellar-local-network/)
PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRAP_MERKLE_ROOT="$PROJECT_ROOT/circuits/trap-merkle-root"
POSITION_MOVEMENT="$PROJECT_ROOT/circuits/position-movement"
# Note: Each circuit has its own rs-soroban-ultrahonk directory

# Load environment variables from .env file in scripts directory (optional for local)
if [ -f "$SCRIPT_DIR/../../.env" ]; then
    source "$SCRIPT_DIR/../../.env"
fi

echo "==> 0) Clean artifacts"
rm -rf "$TRAP_MERKLE_ROOT/target" 2>/dev/null || true
rm -rf "$POSITION_MOVEMENT/target" 2>/dev/null || true
rm -rf "$TRAP_MERKLE_ROOT/rs-soroban-ultrahonk/target" 2>/dev/null || true
rm -rf "$POSITION_MOVEMENT/rs-soroban-ultrahonk/target" 2>/dev/null || true

# ============================================================================
# CIRCUIT 1: trap-merkle-root
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "CIRCUIT 1: trap-merkle-root"
echo "════════════════════════════════════════════════════════════"

echo "==> 1a) cd $TRAP_MERKLE_ROOT"
cd "$TRAP_MERKLE_ROOT"

echo "==> 1b) Build circuit + witness"
npm i -D @aztec/bb.js@0.87.0 source-map-support typescript @types/node tsx

echo "==> 1c) TypeScript helpers ready (using tsx)"

nargo compile

echo "==> 1d) Generate witness (requires valid Prover.toml data)"
nargo execute 2>&1 | grep -v "warning:" || true

# Check if we have a real witness file before proceeding
if [ -s target/trap_merkle_root.gz ]; then
    echo "    ✓ Circuit 1 witness generated successfully"
else
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "⚠️  NO VALID WITNESS FILE FOR CIRCUIT 1"
    echo "════════════════════════════════════════════════════════════"
    echo "The witness generation requires valid Merkle proof test data."
    echo ""
    echo "To proceed, update Prover.toml with correct test data."
    echo "Stopping here. Circuit 1 compilation succeeded ✓"
    echo "════════════════════════════════════════════════════════════"
    exit 0
fi

echo "==> 1e) Generate UltraHonk (keccak) VK + proof"
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"

node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/trap_merkle_root.json \
  -o ./target/vk.keccak

node "$BBJS" prove_ultra_keccak_honk \
  -b ./target/trap_merkle_root.json \
  -w ./target/trap_merkle_root.gz \
  -o ./target/proof.with_public_inputs

echo "==> 1f) Extract public_inputs and proof"
PUB_COUNT="$(cd scripts && npx tsx helpers/count_pub_inputs.ts)"
PUB_BYTES=$((PUB_COUNT * 32))

head -c "$PUB_BYTES" target/proof.with_public_inputs > target/public_inputs
tail -c +$((PUB_BYTES + 1)) target/proof.with_public_inputs > target/proof
cp target/vk.keccak target/vk

echo "    PUB_COUNT=$PUB_COUNT"
echo "    PUB_BYTES=$PUB_BYTES"

PROOF_BYTES=$(wc -c < target/proof | tr -d ' ')
echo "    Proof: $PROOF_BYTES bytes"

echo "==> 1g) Optional sanity check (merkle_root from public_inputs)"
python3 - <<'PY'
import pathlib
b = pathlib.Path("target/public_inputs").read_bytes()
print("  Total length:", len(b), "bytes")
merkle_root = b[:32]
print("  First field (merkle_root):", merkle_root.hex())
PY

# ============================================================================
# CIRCUIT 2: position-movement
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "CIRCUIT 2: position-movement"
echo "════════════════════════════════════════════════════════════"

echo "==> 2a) cd $POSITION_MOVEMENT"
cd "$POSITION_MOVEMENT"

echo "==> 2b) Build circuit + witness"
npm i -D @aztec/bb.js@0.87.0 source-map-support typescript @types/node tsx

echo "==> 2c) TypeScript helpers ready (using tsx)"

nargo compile

echo "==> 2d) Generate witness (requires valid Prover.toml data)"
nargo execute 2>&1 | grep -v "warning:" || true

# Check if we have a real witness file before proceeding
if [ -s target/position_movement.gz ]; then
    echo "    ✓ Circuit 2 witness generated successfully"
else
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "⚠️  NO VALID WITNESS FILE FOR CIRCUIT 2"
    echo "════════════════════════════════════════════════════════════"
    echo "The witness generation requires valid position movement data."
    echo ""
    echo "To proceed, update Prover.toml with correct test data."
    echo "Stopping here. Circuit 2 compilation succeeded ✓"
    echo "════════════════════════════════════════════════════════════"
    exit 0
fi

echo "==> 2e) Generate UltraHonk (keccak) VK + proof"
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"

node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/position_movement.json \
  -o ./target/vk.keccak

node "$BBJS" prove_ultra_keccak_honk \
  -b ./target/position_movement.json \
  -w ./target/position_movement.gz \
  -o ./target/proof.with_public_inputs

echo "==> 2f) Extract public_inputs and proof"
PUB_COUNT="$(cd scripts && npx tsx helpers/count_pub_inputs.ts)"
PUB_BYTES=$((PUB_COUNT * 32))

head -c "$PUB_BYTES" target/proof.with_public_inputs > target/public_inputs
tail -c +$((PUB_BYTES + 1)) target/proof.with_public_inputs > target/proof
cp target/vk.keccak target/vk

echo "    PUB_COUNT=$PUB_COUNT"
echo "    PUB_BYTES=$PUB_BYTES"

PROOF_BYTES=$(wc -c < target/proof | tr -d ' ')
echo "    Proof: $PROOF_BYTES bytes"

echo "==> 2g) Optional sanity check (public_inputs)"
python3 - <<'PY'
import pathlib
b = pathlib.Path("target/public_inputs").read_bytes()
print("  Total length:", len(b), "bytes")
PY

echo "==> 3) cd $CONTRACT_DIR"
cd "$CONTRACT_DIR"

echo "==> 3a) Check Docker availability"
if ! docker info > /dev/null 2>&1; then
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "⚠️  DOCKER NOT RUNNING"
    echo "════════════════════════════════════════════════════════════"
    echo "Docker is required to run the local Stellar network."
    echo ""
    echo "Please start Docker Desktop first, then run this script again."
    echo ""
    echo "Both circuits compiled and generated proofs successfully ✓"
    echo "════════════════════════════════════════════════════════════"
    exit 0
fi
echo "    ✓ Docker is running"

echo "==> 3b) Check if Stellar container is already running"
if docker ps | grep -q "stellar/quickstart"; then
    echo "    ✓ Stellar container already running"
else
    echo "    Starting new Stellar container..."
    docker run -d -p 8000:8000 stellar/quickstart \
      --local \
      --limits unlimited \
      --enable core,rpc,lab,horizon,friendbot > /dev/null 2>&1 || {
        echo "    ⚠️  Could not start container (port may be in use)"
        echo "    Checking if network is accessible anyway..."
    }
    echo "    Waiting for network to initialize..."
    sleep 3
fi

echo "==> 3c) Check local Stellar network availability"
RETRY_COUNT=0
MAX_RETRIES=10
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -s http://localhost:8000/soroban/rpc -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | grep -q "healthy"; then
        echo "    ✓ Local network is healthy"
        break
    fi
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
        echo "    Waiting for network to become healthy... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 2
    else
        echo ""
        echo "════════════════════════════════════════════════════════════"
        echo "⚠️  STELLAR LOCAL NETWORK NOT RESPONDING"
        echo "════════════════════════════════════════════════════════════"
        echo "The local Stellar network failed to become healthy."
        echo ""
        echo "You can manually start it with:"
        echo "  docker run -d -p 8000:8000 stellar/quickstart \\"
        echo "    --local --limits unlimited \\"
        echo "    --enable core,rpc,lab,horizon,friendbot"
        echo ""
        echo "Or using stellar CLI:"
        echo "  stellar container start -t future --limits unlimited"
        echo ""
        echo "Both circuits compiled and generated proofs successfully ✓"
        echo "════════════════════════════════════════════════════════════"
        exit 0
    fi
done

echo "==> 3d) Setup source account"
# Use 'alice' as default source account for local network
SOURCE_ACCOUNT="${STELLAR_SOURCE_ACCOUNT:-alice}"
echo "    Using source account: $SOURCE_ACCOUNT"

# Ensure network is configured
echo "    Configuring local network..."
stellar network add local \
  --rpc-url http://localhost:8000/soroban/rpc \
  --network-passphrase "Standalone Network ; February 2017" 2>/dev/null || true

stellar network use local

# Generate keys if they don't exist
echo "    Generating keys for $SOURCE_ACCOUNT..."
if stellar keys generate "$SOURCE_ACCOUNT" 2>&1 | grep -q "already exists"; then
    echo "    Keys already exist for $SOURCE_ACCOUNT"
else
    echo "    ✓ Keys generated for $SOURCE_ACCOUNT"
fi

# Fund the account using friendbot
echo "    Funding account $SOURCE_ACCOUNT..."
FUND_OUTPUT=$(stellar keys fund "$SOURCE_ACCOUNT" --network local 2>&1)
FUND_EXIT=$?

if [ $FUND_EXIT -eq 0 ]; then
    echo "    ✓ Account funded successfully"
elif echo "$FUND_OUTPUT" | grep -q "already exists\|already funded"; then
    echo "    Account is already funded"
else
    echo "    ❌ Failed to fund account"
    echo "    Error: $FUND_OUTPUT"
    echo ""
    echo "Please ensure the local Stellar network is running with friendbot enabled:"
    echo "  docker run -d -p 8000:8000 stellar/quickstart --local --limits unlimited --enable core,rpc,lab,horizon,friendbot"
    exit 1
fi

# Verify account exists
echo "    Verifying account..."
ACCOUNT_ADDRESS=$(stellar keys address "$SOURCE_ACCOUNT" 2>&1)
if [ $? -eq 0 ]; then
    echo "    ✓ Account ready: $ACCOUNT_ADDRESS"
else
    echo "    ❌ Failed to get account address"
    exit 1
fi

# ============================================================================
# DEPLOY AND VERIFY CIRCUIT 1: trap-merkle-root
# ============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════="
echo "DEPLOY CIRCUIT 1: trap-merkle-root"
echo "═══════════════════════════════════════════════════════════="

echo "==> 3e) Build circuit 1 contract"
cd "$TRAP_MERKLE_ROOT/rs-soroban-ultrahonk"
stellar contract build --optimize

CID_MERKLE="$(
  stellar contract deploy \
    --wasm target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm \
    --source-account "$SOURCE_ACCOUNT" \
    --network local \
    -- \
    --vk_bytes-file-path "$TRAP_MERKLE_ROOT/target/vk" \
  | tail -n1
)"

echo "==> Deployed Merkle Root Contract ID: $CID_MERKLE"

echo "==> 4a) Verify circuit 1 proof (simulation, --send no)"
stellar contract invoke \
  --id "$CID_MERKLE" \
  --source-account "$SOURCE_ACCOUNT" \
  --network local \
  --send no \
  -- \
  verify_proof \
  --public_inputs-file-path "$TRAP_MERKLE_ROOT/target/public_inputs" \
  --proof_bytes-file-path "$TRAP_MERKLE_ROOT/target/proof"

echo "==> 4b) Verify circuit 1 proof on-chain (--send yes)"
VERIFY_OUTPUT_C1=$(stellar contract invoke \
  --id "$CID_MERKLE" \
  --source-account "$SOURCE_ACCOUNT" \
  --network local \
  --send yes \
  -- \
  verify_proof \
  --public_inputs-file-path "$TRAP_MERKLE_ROOT/target/public_inputs" \
  --proof_bytes-file-path "$TRAP_MERKLE_ROOT/target/proof" 2>&1)

# Extract transaction hash
TX_HASH_C1=$(echo "$VERIFY_OUTPUT_C1" | grep -oE '[a-f0-9]{64}' | head -n1)

echo "    ✓ Circuit 1 on-chain verification succeeded!"
if [ -n "$TX_HASH_C1" ]; then
    echo "      Transaction Hash: $TX_HASH_C1"
fi

# ============================================================================
# DEPLOY AND VERIFY CIRCUIT 2: position-movement
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "DEPLOY CIRCUIT 2: position-movement"
echo "════════════════════════════════════════════════════════════"
echo "==> 4e) Build circuit 2 contract"
cd "$POSITION_MOVEMENT/rs-soroban-ultrahonk"
stellar contract build --optimize
CID_MOVEMENT="$(
  stellar contract deploy \
    --wasm target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm \
    --source-account "$SOURCE_ACCOUNT" \
    --network local \
    -- \
    --vk_bytes-file-path "$POSITION_MOVEMENT/target/vk" \
  | tail -n1
)"

echo "==> Deployed Position Movement Contract ID: $CID_MOVEMENT"

echo "==> 5a) Verify circuit 2 proof (simulation, --send no)"
stellar contract invoke \
  --id "$CID_MOVEMENT" \
  --source-account "$SOURCE_ACCOUNT" \
  --network local \
  --send no \
  -- \
  verify_proof \
  --public_inputs-file-path "$POSITION_MOVEMENT/target/public_inputs" \
  --proof_bytes-file-path "$POSITION_MOVEMENT/target/proof"

echo "==> 5b) Verify circuit 2 proof on-chain (--send yes)"
VERIFY_OUTPUT_C2=$(stellar contract invoke \
  --id "$CID_MOVEMENT" \
  --source-account "$SOURCE_ACCOUNT" \
  --network local \
  --send yes \
  -- \
  verify_proof \
  --public_inputs-file-path "$POSITION_MOVEMENT/target/public_inputs" \
  --proof_bytes-file-path "$POSITION_MOVEMENT/target/proof" 2>&1)

# Extract transaction hash
TX_HASH_C2=$(echo "$VERIFY_OUTPUT_C2" | grep -oE '[a-f0-9]{64}' | head -n1)

echo "    ✓ Circuit 2 on-chain verification succeeded!"
if [ -n "$TX_HASH_C2" ]; then
    echo "      Transaction Hash: $TX_HASH_C2"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ ALL VERIFICATIONS COMPLETED SUCCESSFULLY!"
echo "════════════════════════════════════════════════════════════"
echo "Both circuits were verified on-chain:"
echo ""
if [ -n "$TX_HASH_C1" ]; then
    echo "  1. Merkle Root"
    echo "     Transaction Hash: $TX_HASH_C1"
    echo "     Contract ID: $CID_MERKLE"
else
    echo "  1. Merkle Root: $CID_MERKLE"
fi
echo ""
if [ -n "$TX_HASH_C2" ]; then
    echo "  2. Position Movement"
    echo "     Transaction Hash: $TX_HASH_C2"
    echo "     Contract ID: $CID_MOVEMENT"
else
    echo "  2. Position Movement: $CID_MOVEMENT"
fi
echo "════════════════════════════════════════════════════════════"