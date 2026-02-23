#!/usr/bin/env bash
set -euo pipefail

# Fix for Rust compilation with long paths
export TMPDIR="${TMPDIR:-/tmp}"
mkdir -p "$TMPDIR"

# Use shorter build directory for Cargo to avoid path issues
export CARGO_TARGET_DIR="/tmp/cargo-build-$$"
mkdir -p "$CARGO_TARGET_DIR"

# ============================================================================
# Trap Commitment Circuit - Stellar Testnet Deployment Script
# ============================================================================
# This script deploys and verifies ONLY the trap-commitment circuit
# on Stellar testnet.
#
# ✅ Circuit (trap-commitment) successfully verifies on testnet!
#
# The trap commitment circuit generates cryptographic commitments for trap
# values and validates them using poseidon hash and merkle trees.
#
# CIRCUIT:
# - trap-commitment: Generates and verifies trap commitments using
#   poseidon hash and binary merkle root
# ============================================================================

# Set ROOT to project root (3 levels up from scripts/e2e/stellar-testnet/)
PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRAP_COMMITMENT="$PROJECT_ROOT/circuits/trap-commitment"
CONTRACT_DIR="$TRAP_COMMITMENT/rs-soroban-ultrahonk"

# Load environment variables from .env file in scripts directory
if [ -f "$SCRIPT_DIR/../../.env" ]; then
    echo "==> Loading .env file"
    source "$SCRIPT_DIR/../../.env"
fi

echo "==> 0) Clean circuit artifacts"
rm -rf "$TRAP_COMMITMENT/target" 2>/dev/null || true

# ============================================================================
# CIRCUIT: trap-commitment
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "CIRCUIT: trap-commitment"
echo "════════════════════════════════════════════════════════════"

echo "==> 1a) cd $TRAP_COMMITMENT"
cd "$TRAP_COMMITMENT"

echo "==> 1b) Build circuit + witness"
npm i -D @aztec/bb.js@0.87.0 source-map-support typescript @types/node tsx

echo "==> 1c) TypeScript helpers ready (using tsx)"

nargo compile
nargo execute

echo "==> 1d) Generate UltraHonk (keccak) VK + proof"
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"

node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/trap_commitment.json \
  -o ./target/vk.keccak

node "$BBJS" prove_ultra_keccak_honk \
  -b ./target/trap_commitment.json \
  -w ./target/trap_commitment.gz \
  -o ./target/proof.with_public_inputs

echo "==> 1e) Split proof into public_inputs + proof bytes"
PUB_COUNT="$(cd scripts && npx tsx helpers/count_pub_inputs.ts)"
PUB_BYTES=$((PUB_COUNT * 32))

head -c "$PUB_BYTES" target/proof.with_public_inputs > target/public_inputs
tail -c +$((PUB_BYTES + 1)) target/proof.with_public_inputs > target/proof
cp target/vk.keccak target/vk

echo "    PUB_COUNT=$PUB_COUNT"
echo "    PUB_BYTES=$PUB_BYTES"

PROOF_BYTES=$(wc -c < target/proof | tr -d ' ')
echo "    Proof: $PROOF_BYTES bytes"

echo "==> 1f) Optional sanity check (public_inputs)"
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

echo "==> 2b) Build contract"
stellar contract build --optimize

# ============================================================================
# DEPLOY AND VERIFY CIRCUIT: trap-commitment
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "DEPLOY CIRCUIT: trap-commitment"
echo "════════════════════════════════════════════════════════════"

CID_COMMITMENT="$(
  stellar contract deploy \
    --wasm target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm \
    --source-account "$SOURCE_ACCOUNT" \
    --network testnet \
    -- \
    --vk_bytes-file-path "$TRAP_COMMITMENT/target/vk" \
  | tail -n1
)"

echo "==> Deployed Trap Commitment Contract ID: $CID_COMMITMENT"
echo ""
echo "═══════════════════════════════════════"
echo "✅ Circuit deployment successful!"
echo "🔗 Contract ID: $CID_COMMITMENT"
echo "═══════════════════════════════════════"
echo ""
echo "==> 3) Attempting proof verification on testnet..."
echo ""

# Try verification and capture the result
set +e  # Temporarily disable exit on error
VERIFY_OUTPUT=$(stellar contract invoke \
  --id "$CID_COMMITMENT" \
  --source-account "$SOURCE_ACCOUNT" \
  --network testnet \
  --send yes \
  -- \
  verify_proof \
  --public_inputs-file-path "$TRAP_COMMITMENT/target/public_inputs" \
  --proof_bytes-file-path "$TRAP_COMMITMENT/target/proof" 2>&1)
VERIFY_EXIT=$?
set -e  # Re-enable exit on error

if [ $VERIFY_EXIT -eq 0 ]; then
    # Extract transaction hash from output
    TX_HASH=$(echo "$VERIFY_OUTPUT" | grep -oE '[a-f0-9]{64}' | head -n1)
    
    echo ""
    echo "═══════════════════════════════════════════════════════════="
    echo "✅ VERIFICATION SUCCESSFUL!"
    echo "═══════════════════════════════════════════════════════════="
    echo "🎉 The trap-commitment circuit proof was verified"
    echo "   successfully on Stellar testnet!"
    echo ""
    if [ -n "$TX_HASH" ]; then
        echo "Transaction Hash: $TX_HASH"
        echo "🔗 https://stellar.expert/explorer/testnet/tx/$TX_HASH"
        echo "🔗 https://testnet.stellarchain.io/transactions/$TX_HASH"
        echo ""
    fi
    echo "Contract ID: $CID_COMMITMENT"
    echo ""
    echo "This demonstrates that the trap commitment circuit using"
    echo "poseidon hash and binary merkle root can verify successfully"
    echo "within Stellar's protocol limits."
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
    echo "Contract ID: $CID_COMMITMENT"
    echo "════════════════════════════════════════════════════════════"
    exit 1
fi
