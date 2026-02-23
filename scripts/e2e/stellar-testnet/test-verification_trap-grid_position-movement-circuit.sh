#!/usr/bin/env bash
set -euo pipefail

# Fix for Rust compilation with long paths
export TMPDIR="${TMPDIR:-/tmp}"
mkdir -p "$TMPDIR"

# Use shorter build directory for Cargo to avoid path issues
export CARGO_TARGET_DIR="/tmp/cargo-build-$$"
mkdir -p "$CARGO_TARGET_DIR"

# ============================================================================
# Position Movement Circuit - Stellar Testnet Deployment Script
# ============================================================================
# This script deploys and verifies ONLY the position-movement circuit
# on Stellar testnet.
#
# CIRCUIT STRUCTURE (Simplified - No Commitments):
# - Public inputs (3 fields): move_x, move_y, is_hit
# - Private inputs: trap_value
# - Constraints: coordinate bounds checking, boolean validation, value matching
#
# The circuit has been simplified to remove all cryptographic commitments
# and Merkle proof verification, containing only basic constraint checks.
# This minimizes the circuit size to:
#   - 20 ACIR opcodes
#   - 3 public input fields (96 bytes)
#
# VERIFICATION STATUS:
# Testing required after circuit simplification
# ============================================================================

# Set ROOT to project root (3 levels up from scripts/e2e/stellar-testnet/)
PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
POSITION_MOVEMENT="$PROJECT_ROOT/circuits/position-movement"
CONTRACT_DIR="$POSITION_MOVEMENT/rs-soroban-ultrahonk"

# Load environment variables from .env file in scripts directory
if [ -f "$SCRIPT_DIR/../../.env" ]; then
    echo "==> Loading .env file"
    source "$SCRIPT_DIR/../../.env"
fi

echo "==> 0) Clean circuit artifacts"
rm -rf "$POSITION_MOVEMENT/target" 2>/dev/null || true
rm -rf "$CONTRACT_DIR/target" 2>/dev/null || true
echo "    Cleaned circuit and contract build artifacts"

# ============================================================================
# CIRCUIT: position-movement
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "CIRCUIT: position-movement"
echo "════════════════════════════════════════════════════════════"

echo "==> 1a) cd $POSITION_MOVEMENT"
cd "$POSITION_MOVEMENT"

echo "==> 1b) Build circuit + witness"
npm i -D @aztec/bb.js@0.87.0 source-map-support typescript @types/node tsx

echo "==> 1c) TypeScript helpers ready (using tsx)"

echo "==> 1d) Check circuit structure"
nargo info
echo ""

nargo compile
nargo execute

echo "==> 1e) Generate UltraHonk (keccak) VK + proof"
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"

node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/position_movement.json \
  -o ./target/vk.keccak

node "$BBJS" prove_ultra_keccak_honk \
  -b ./target/position_movement.json \
  -w ./target/position_movement.gz \
  -o ./target/proof.with_public_inputs

echo "==> 1f) Split proof into public_inputs + proof bytes"
PUB_COUNT="$(cd scripts && npx tsx helpers/count_pub_inputs.ts)"
PUB_BYTES=$((PUB_COUNT * 32))

head -c "$PUB_BYTES" target/proof.with_public_inputs > target/public_inputs
tail -c +$((PUB_BYTES + 1)) target/proof.with_public_inputs > target/proof
cp target/vk.keccak target/vk

echo "    PUB_COUNT=$PUB_COUNT"
echo "    PUB_BYTES=$PUB_BYTES"

PROOF_BYTES=$(wc -c < target/proof | tr -d ' ')
echo "    Proof: $PROOF_BYTES bytes"

echo "==> 1g) Optional sanity check (public_inputs)"
python3 - <<'PY'
import pathlib
b = pathlib.Path("target/public_inputs").read_bytes()
print("  Total length:", len(b), "bytes")
# Display first few fields
num_fields = len(b) // 32
print(f"  Number of public input fields: {num_fields}")
for i in range(min(num_fields, 4)):
    field_bytes = b[i*32:(i+1)*32]
    print(f"  Field {i}: 0x{field_bytes.hex()}")
PY

echo "==> 2) cd $CONTRACT_DIR"
cd "$CONTRACT_DIR"

echo "==> 2a) Setup source account for testnet"
# Use environment variable or prompt user to set their testnet identity
SOURCE_ACCOUNT="${STELLAR_SOURCE_ACCOUNT:-}"
if [ -z "$SOURCE_ACCOUNT" ]; then
    echo "    ⚠️  STELLAR_SOURCE_ACCOUNT not set"
    echo "    Please set your testnet identity name:"
    echo "    export STELLAR_SOURCE_ACCOUNT=your-testnet-identity"
    echo ""
    echo "    To create and fund a testnet account:"
    echo "    1. stellar keys generate your-testnet-identity"
    echo "    2. stellar keys fund your-testnet-identity --network testnet"
    exit 1
fi
echo "    Using source account: $SOURCE_ACCOUNT"

echo "==> 2b) Build contract (resetting CARGO_TARGET_DIR)"
# Unset CARGO_TARGET_DIR so contract builds in standard location
unset CARGO_TARGET_DIR
stellar contract build --optimize

# Verify the wasm file was created
WASM_PATH="target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm"
if [ ! -f "$WASM_PATH" ]; then
    echo "    ❌ Error: Contract wasm file not found at $WASM_PATH"
    echo "    Build may have failed. Check the output above."
    exit 1
fi
echo "    ✓ Contract built successfully"
ls -lh "$WASM_PATH"

# ============================================================================
# DEPLOY AND VERIFY CIRCUIT: trap-grid-position-movement
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "DEPLOY CIRCUIT: trap-grid-position-movement"
echo "════════════════════════════════════════════════════════════"

CID_MOVEMENT="$(
  stellar contract deploy \
    --wasm target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm \
    --source-account "$SOURCE_ACCOUNT" \
    --network testnet \
    -- \
    --vk_bytes-file-path "$POSITION_MOVEMENT/target/vk" \
  | tail -n1
)"

echo "==> Deployed Position Movement Contract ID: $CID_MOVEMENT"
echo ""
echo "════════════════════════════════════════════════════════════"
echo "✅ Circuit deployment successful!"
echo "🔗 Contract ID: $CID_MOVEMENT"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "==> 3) Attempting proof verification on testnet..."
echo ""

# Try verification and capture the result
set +e  # Temporarily disable exit on error
VERIFY_OUTPUT=$(stellar contract invoke \
  --id "$CID_MOVEMENT" \
  --source-account "$SOURCE_ACCOUNT" \
  --network testnet \
  --send yes \
  -- \
  verify_proof \
  --public_inputs-file-path "$POSITION_MOVEMENT/target/public_inputs" \
  --proof_bytes-file-path "$POSITION_MOVEMENT/target/proof" 2>&1)
VERIFY_EXIT=$?
set -e  # Re-enable exit on error

if [ $VERIFY_EXIT -eq 0 ]; then
    # Extract transaction hash from output
    TX_HASH=$(echo "$VERIFY_OUTPUT" | grep -oE '[a-f0-9]{64}' | head -n1)
    
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "✅ VERIFICATION SUCCESSFUL!"
    echo "════════════════════════════════════════════════════════════"
    echo "🎉 The position-movement circuit proof was verified"
    echo "   successfully on Stellar testnet!"
    echo ""
    if [ -n "$TX_HASH" ]; then
        echo "Transaction Hash: $TX_HASH"
        echo "🔗 https://stellar.expert/explorer/testnet/tx/$TX_HASH"
        echo "🔗 https://testnet.stellarchain.io/transactions/$TX_HASH"
        echo ""
    fi
    echo "Contract ID: $CID_MOVEMENT"
    echo ""
    echo "This demonstrates that the position-movement circuit"
    echo "is efficient enough to verify within Stellar's protocol limits."
    echo "════════════════════════════════════════════════════════════"
else
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "❌ VERIFICATION FAILED"
    echo "════════════════════════════════════════════════════════════"
    echo "The proof verification failed on Stellar testnet."
    echo ""
    echo "Error details:"
    echo "$VERIFY_OUTPUT"
    echo ""
    
    # Check if it's a budget exceeded error
    if echo "$VERIFY_OUTPUT" | grep -q "ExceededLimit"; then
        echo "⚠️  Issue: Stellar Protocol CPU Budget Exceeded"
        echo ""
        echo "The UltraHonk proof verification requires more computational"
        echo "resources than Stellar's protocol limits allow."
        echo ""
        echo "Possible solutions:"
        echo "  1. Further optimize the circuit (reduce constraints)"
        echo "  2. Use a lighter proof system (UltraPlonk instead of UltraHonk)"
        echo "  3. Explore proof aggregation/recursion techniques"
        echo "  4. Wait for protocol limit increases in future Stellar upgrades"
    else
        echo "This could be due to:"
        echo "  - Protocol CPU instruction limits"
        echo "  - Invalid proof or public inputs"
        echo "  - Network issues"
    fi
    echo ""
    echo "💡 Try running the local test to verify circuit correctness:"
    echo "   sh test-local_trap-grid_all-circuits.sh"
    echo ""
    echo "Contract ID: $CID_MOVEMENT"
    echo "════════════════════════════════════════════════════════════"
    exit 1
fi
