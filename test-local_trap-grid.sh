#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Trap Grid ZK Circuit - Local Test Script
# ============================================================================
# This script compiles the trap grid ZK circuit, generates proofs, and verifies
# them on a local Stellar network.
#
# PREREQUISITES:
#   1. Valid test data in trap_grid/Prover.toml with:
#      - trap_merkle_root: Merkle root commitment of the trap grid
#      - move coordinates and claim (is_hit)
#      - Valid Merkle proof (indices + siblings) for the move
#      - trap_value that matches is_hit
#
#   2. Local Stellar network running (for deployment steps)
#      Run: stellar container start -t future --limits unlimited
#
#   3. Source account configured (default: 'alice')
#      The account must exist and be funded on the local network
#      Set STELLAR_SOURCE_ACCOUNT env var to use a different account
#
# NOTE: If Prover.toml doesn't have cryptographically valid Merkle proof data,
#       the script will stop after circuit compilation with instructions.
# ============================================================================

ROOT="$(cd "$(dirname "$0")" && pwd)"
LIMIT_ORDERS_DIR="$ROOT/trap_grid"
CONTRACT_DIR="$ROOT/rs-soroban-ultrahonk"

echo "==> 0) Clean artifacts"
rm -rf "$LIMIT_ORDERS_DIR/target"
rm -rf "$CONTRACT_DIR/target"

echo "==> 1) cd $LIMIT_ORDERS_DIR"
cd "$LIMIT_ORDERS_DIR"

echo "==> 2) Build circuit + witness"
npm i -D @aztec/bb.js@0.87.0 source-map-support
nargo compile

echo "==> 2a) Generate witness (requires valid Prover.toml data)"
nargo execute 2>&1 | grep -v "warning:" || true

# Check if we have a real witness file before proceeding
if [ -s target/trap_grid.gz ]; then
    echo "    ✓ Witness generated successfully"
else
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "⚠️  NO VALID WITNESS FILE AVAILABLE"
    echo "════════════════════════════════════════════════════════════"
    echo "The witness generation requires valid Merkle proof test data."
    echo ""
    echo "To proceed with proof generation, you need to:"
    echo "  1. Generate a valid trap grid Merkle tree"
    echo "  2. Update Prover.toml with correct test data including:"
    echo "     - Valid trap_merkle_root"
    echo "     - Correct merkle_proof_indices"
    echo "     - Correct merkle_proof_siblings"
    echo ""
    echo "Stopping here. Circuit compilation succeeded ✓"
    echo "════════════════════════════════════════════════════════════"
    exit 0
fi

echo "==> 3) Generate UltraHonk (keccak) VK + proof"
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"

node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/trap_grid.json \
  -o ./target/vk.keccak

node "$BBJS" prove_ultra_keccak_honk \
  -b ./target/trap_grid.json \
  -w ./target/trap_grid.gz \
  -o ./target/proof.with_public_inputs

echo "==> 4) Extract public_inputs and proof"
# Now that public_inputs is properly marked as 'pub', bb.js includes
# public inputs at the start of proof.with_public_inputs.
# Calculate the number of public input fields from the ABI.
PUB_COUNT="$(node count_pub_inputs.js)"
PUB_BYTES=$((PUB_COUNT * 32))

head -c "$PUB_BYTES" target/proof.with_public_inputs > target/public_inputs
tail -c +$((PUB_BYTES + 1)) target/proof.with_public_inputs > target/proof
cp target/vk.keccak target/vk

echo "    PUB_COUNT=$PUB_COUNT"
echo "    PUB_BYTES=$PUB_BYTES"

PROOF_BYTES=$(wc -c < target/proof | tr -d ' ')
echo "    Proof: $PROOF_BYTES bytes (should be 14592)"

echo "==> Optional sanity check (trap_merkle_root from public_inputs)"
python3 - <<'PY'
import pathlib
b = pathlib.Path("target/public_inputs").read_bytes()
print("  Total length:", len(b), "bytes")
merkle_root = b[:32]
print("  First field (trap_merkle_root):", merkle_root.hex())
PY

echo "==> 5) cd $CONTRACT_DIR"
cd "$CONTRACT_DIR"

echo "==> 5a) Check local Stellar network availability"
if ! curl -s http://localhost:8000/soroban/rpc -X POST -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' | grep -q "healthy"; then
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "⚠️  STELLAR LOCAL NETWORK NOT AVAILABLE"
    echo "════════════════════════════════════════════════════════════"
    echo "The local Stellar network is not running or not ready."
    echo ""
    echo "To start the local network, run:"
    echo "  stellar container start -t future --limits unlimited"
    echo ""
    echo "Wait a few moments for the network to become healthy, then"
    echo "run this script again."
    echo ""
    echo "The circuit compilation and proof generation succeeded ✓"
    echo "════════════════════════════════════════════════════════════"
    exit 0
fi
echo "    ✓ Local network is healthy"

echo "==> 5b) Setup source account"
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

echo "==> 5c) Build + deploy contract with VK bytes"
stellar contract build --optimize

CID="$(
  stellar contract deploy \
    --wasm target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm \
    --source-account "$SOURCE_ACCOUNT" \
    --network local \
    -- \
    --vk_bytes-file-path "$LIMIT_ORDERS_DIR/target/vk" \
  | tail -n1
)"

echo "==> Deployed CID: $CID"

echo "==> 6) Verify proof (simulation, --send no)"
stellar contract invoke \
  --id "$CID" \
  --source-account "$SOURCE_ACCOUNT" \
  --network local \
  --send no \
  -- \
  verify_proof \
  --public_inputs-file-path "$LIMIT_ORDERS_DIR/target/public_inputs" \
  --proof_bytes-file-path "$LIMIT_ORDERS_DIR/target/proof"

echo "==> 7) Verify proof on-chain (--send yes)"
stellar contract invoke \
  --id "$CID" \
  --source-account "$SOURCE_ACCOUNT" \
  --network local \
  --send yes \
  -- \
  verify_proof \
  --public_inputs-file-path "$LIMIT_ORDERS_DIR/target/public_inputs" \
  --proof_bytes-file-path "$LIMIT_ORDERS_DIR/target/proof"

echo "==> Done! On-chain verification succeeded."