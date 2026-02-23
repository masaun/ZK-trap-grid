#!/usr/bin/env bash
set -euo pipefail

# Fix for Rust compilation with long paths
export TMPDIR="${TMPDIR:-/tmp}"
mkdir -p "$TMPDIR"

# Use shorter build directory for Cargo to avoid path issues
export CARGO_TARGET_DIR="/tmp/cargo-build-$$"
mkdir -p "$CARGO_TARGET_DIR"

# ============================================================================
# Trap Grid ZK Circuits - Stellar Testnet Deployment Script
# ============================================================================
# ⚠️  TESTNET LIMITATION: The trap_grid circuits verification currently exceeds
# Stellar testnet's protocol-level CPU instruction limits.
#
# This script successfully:
# ✅ Deploys the verifier contracts to testnet
# ❌ Verification fails with "HostError: Error(Budget, ExceededLimit)"
#
# The budget limit is a hard protocol constraint (~100M CPU instructions per
# transaction). The trap_grid circuits require significantly more.
#
# For working verification, use the local network:
#   sh test-local_trap-grid.sh
#
# This script is useful for:
# - Testing deployment to testnet
# - Demonstrating the contract deployment process
# - Awaiting future protocol upgrades with higher limits
#
# CIRCUITS:
# 1. trap-merkle-root: Verifies the trap grid merkle root
# 2. position-movement: Verifies position movement and trap detection
# 3. trap-commitment: Verifies trap commitments
# ============================================================================

# Set ROOT to project root (3 levels up from scripts/e2e/stellar-testnet/)
PROJECT_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TRAP_MERKLE_ROOT="$PROJECT_ROOT/circuits/trap-merkle-root"
POSITION_MOVEMENT="$PROJECT_ROOT/circuits/position-movement"
TRAP_COMMITMENT="$PROJECT_ROOT/circuits/trap-commitment"

# Load environment variables from .env file in scripts directory
if [ -f "$SCRIPT_DIR/../../.env" ]; then
    echo "==> Loading .env file"
    source "$SCRIPT_DIR/../../.env"
fi

echo "==> 0) Clean circuit artifacts"
rm -rf "$TRAP_MERKLE_ROOT/target" 2>/dev/null || true
rm -rf "$POSITION_MOVEMENT/target" 2>/dev/null || true
rm -rf "$TRAP_COMMITMENT/target" 2>/dev/null || true

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
nargo execute

echo "==> 1d) Generate UltraHonk (keccak) VK + proof"
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"

node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/trap_merkle_root.json \
  -o ./target/vk.keccak

node "$BBJS" prove_ultra_keccak_honk \
  -b ./target/trap_merkle_root.json \
  -w ./target/trap_merkle_root.gz \
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

echo "==> 1f) Optional sanity check (merkle_root from public_inputs)"
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
nargo execute

echo "==> 2d) Generate UltraHonk (keccak) VK + proof"
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"

node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/position_movement.json \
  -o ./target/vk.keccak

node "$BBJS" prove_ultra_keccak_honk \
  -b ./target/position_movement.json \
  -w ./target/position_movement.gz \
  -o ./target/proof.with_public_inputs

echo "==> 2e) Split proof into public_inputs + proof bytes"
PUB_COUNT="$(cd scripts && npx tsx helpers/count_pub_inputs.ts)"
PUB_BYTES=$((PUB_COUNT * 32))

head -c "$PUB_BYTES" target/proof.with_public_inputs > target/public_inputs
tail -c +$((PUB_BYTES + 1)) target/proof.with_public_inputs > target/proof
cp target/vk.keccak target/vk

echo "    PUB_COUNT=$PUB_COUNT"
echo "    PUB_BYTES=$PUB_BYTES"

PROOF_BYTES=$(wc -c < target/proof | tr -d ' ')
echo "    Proof: $PROOF_BYTES bytes"

echo "==> 2f) Optional sanity check (public_inputs)"
python3 - <<'PY'
import pathlib
b = pathlib.Path("target/public_inputs").read_bytes()
print("  Total length:", len(b), "bytes")
PY

echo "==> 3) Setup source account for testnet"
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

# ============================================================================
# DEPLOY AND VERIFY CIRCUIT 1: trap-merkle-root
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "DEPLOY CIRCUIT 1: trap-merkle-root"
echo "════════════════════════════════════════════════════════════"

echo "==> 4a) Build circuit 1 contract"
cd "$TRAP_MERKLE_ROOT/rs-soroban-ultrahonk"
stellar contract build --optimize

CID_MERKLE="$(
  stellar contract deploy \
    --wasm target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm \
    --source-account "$SOURCE_ACCOUNT" \
    --network testnet \
    -- \
    --vk_bytes-file-path "$TRAP_MERKLE_ROOT/target/vk" \
  | tail -n1
)"

echo "==> Deployed Merkle Root Contract ID: $CID_MERKLE"
echo ""
echo "═══════════════════════════════════════"
echo "✅ Circuit 1 deployment successful!"
echo "🔗 Contract ID: $CID_MERKLE"
echo ""
echo "⚠️  Note: Proof verification on testnet will likely fail due to"
echo "protocol CPU instruction limits (~100M per transaction)."
echo "═══════════════════════════════════════"
echo ""
echo "==> 4b) Check circuit 1 proof sizes"
PROOF_SIZE_C1=$(wc -c < "$TRAP_MERKLE_ROOT/target/proof" | tr -d ' ')
PUB_INPUT_SIZE_C1=$(wc -c < "$TRAP_MERKLE_ROOT/target/public_inputs" | tr -d ' ')
echo "    Proof size: $PROOF_SIZE_C1 bytes"
echo "    Public inputs size: $PUB_INPUT_SIZE_C1 bytes"
echo ""

echo "==> 4c) Try simulation first (--send no)"
set +e
SIM_OUTPUT_C1=$(stellar contract invoke \
  --id "$CID_MERKLE" \
  --source-account "$SOURCE_ACCOUNT" \
  --network testnet \
  --send no \
  -- \
  verify_proof \
  --public_inputs-file-path "$TRAP_MERKLE_ROOT/target/public_inputs" \
  --proof_bytes-file-path "$TRAP_MERKLE_ROOT/target/proof" 2>&1)
SIM_EXIT_C1=$?

if [ $SIM_EXIT_C1 -ne 0 ]; then
    echo "    ⚠️  Simulation failed (expected for large circuits)"
    echo ""
else
    echo "    ✓ Simulation successful"
    echo ""
fi

echo "==> 4d) Attempting proof verification for circuit 1 (expected to fail)"
echo "    This demonstrates the protocol limitation..."

VERIFY_OUTPUT_C1=$(stellar contract invoke \
  --id "$CID_MERKLE" \
  --source-account "$SOURCE_ACCOUNT" \
  --network testnet \
  --send yes \
  -- \
  verify_proof \
  --public_inputs-file-path "$TRAP_MERKLE_ROOT/target/public_inputs" \
  --proof_bytes-file-path "$TRAP_MERKLE_ROOT/target/proof" 2>&1)
VERIFY_EXIT_C1=$?
set -e

if [ $VERIFY_EXIT_C1 -eq 0 ]; then
    # Extract transaction hash
    TX_HASH_C1=$(echo "$VERIFY_OUTPUT_C1" | grep -oE '[a-f0-9]{64}' | head -n1)
    echo ""
    echo "═══════════════════════════════════════"
    echo "✅ Circuit 1 verification succeeded!"
    if [ -n "$TX_HASH_C1" ]; then
        echo "Transaction Hash: $TX_HASH_C1"
        echo "🔗 https://stellar.expert/explorer/testnet/tx/$TX_HASH_C1"
    fi
    echo "Contract ID: $CID_MERKLE"
    echo "═══════════════════════════════════════"
else
    echo ""
    echo "═══════════════════════════════════════"
    echo "❌ Circuit 1 verification failed (expected)"
    echo "═══════════════════════════════════════"
    
    # Show error type
    if echo "$VERIFY_OUTPUT_C1" | grep -q "TxSorobanInvalid"; then
        echo "Error: TxSorobanInvalid - Transaction rejected during validation"
    elif echo "$VERIFY_OUTPUT_C1" | grep -q "ExceededLimit"; then
        echo "Error: ExceededLimit - Protocol CPU/memory budget exceeded"
    fi
    
    echo "Proof size: $PROOF_SIZE_C1 bytes"
    echo "Public inputs: $PUB_INPUT_SIZE_C1 bytes"
    echo ""
    echo "This demonstrates Stellar's current protocol limits for"
    echo "computationally expensive ZK proof verification."
    echo "═══════════════════════════════════════"
fi

# ============================================================================
# DEPLOY AND VERIFY CIRCUIT 2: position-movement
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "DEPLOY CIRCUIT 2: position-movement"
echo "════════════════════════════════════════════════════════════"

echo "==> 5a) Build circuit 2 contract"
cd "$POSITION_MOVEMENT/rs-soroban-ultrahonk"
stellar contract build --optimize

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
echo "═══════════════════════════════════════"
echo "✅ Circuit 2 deployment successful!"
echo "🔗 Contract ID: $CID_MOVEMENT"
echo ""
echo "⚠️  Note: Proof verification on testnet will likely fail due to"
echo "protocol CPU instruction limits (~100M per transaction)."
echo "═══════════════════════════════════════"
echo ""
echo "==> 5b) Check circuit 2 proof sizes"
PROOF_SIZE_C2=$(wc -c < "$POSITION_MOVEMENT/target/proof" | tr -d ' ')
PUB_INPUT_SIZE_C2=$(wc -c < "$POSITION_MOVEMENT/target/public_inputs" | tr -d ' ')
echo "    Proof size: $PROOF_SIZE_C2 bytes"
echo "    Public inputs size: $PUB_INPUT_SIZE_C2 bytes"
echo ""

echo "==> 5c) Try simulation first (--send no)"
set +e
SIM_OUTPUT_C2=$(stellar contract invoke \
  --id "$CID_MOVEMENT" \
  --source-account "$SOURCE_ACCOUNT" \
  --network testnet \
  --send no \
  -- \
  verify_proof \
  --public_inputs-file-path "$POSITION_MOVEMENT/target/public_inputs" \
  --proof_bytes-file-path "$POSITION_MOVEMENT/target/proof" 2>&1)
SIM_EXIT_C2=$?

if [ $SIM_EXIT_C2 -ne 0 ]; then
    echo "    ⚠️  Simulation failed (expected for large circuits)"
    echo ""
else
    echo "    ✓ Simulation successful"
    echo ""
fi

echo "==> 5d) Attempting proof verification for circuit 2 (expected to fail)"
echo "    This demonstrates the protocol limitation..."

VERIFY_OUTPUT_C2=$(stellar contract invoke \
  --id "$CID_MOVEMENT" \
  --source-account "$SOURCE_ACCOUNT" \
  --network testnet \
  --send yes \
  -- \
  verify_proof \
  --public_inputs-file-path "$POSITION_MOVEMENT/target/public_inputs" \
  --proof_bytes-file-path "$POSITION_MOVEMENT/target/proof" 2>&1)
VERIFY_EXIT_C2=$?
set -e

if [ $VERIFY_EXIT_C2 -eq 0 ]; then
    # Extract transaction hash
    TX_HASH_C2=$(echo "$VERIFY_OUTPUT_C2" | grep -oE '[a-f0-9]{64}' | head -n1)
    echo ""
    echo "═══════════════════════════════════════"
    echo "✅ Circuit 2 verification succeeded!"
    if [ -n "$TX_HASH_C2" ]; then
        echo "Transaction Hash: $TX_HASH_C2"
        echo "🔗 https://stellar.expert/explorer/testnet/tx/$TX_HASH_C2"
    fi
    echo "Contract ID: $CID_MOVEMENT"
    echo "═══════════════════════════════════════"
else
    echo ""
    echo "═══════════════════════════════════════"
    echo "❌ Circuit 2 verification failed (expected)"
    echo "═══════════════════════════════════════"
    
    # Show error type
    if echo "$VERIFY_OUTPUT_C2" | grep -q "TxSorobanInvalid"; then
        echo "Error: TxSorobanInvalid - Transaction rejected during validation"
    elif echo "$VERIFY_OUTPUT_C2" | grep -q "ExceededLimit"; then
        echo "Error: ExceededLimit - Protocol CPU/memory budget exceeded"
    fi
    
    echo "Proof size: $PROOF_SIZE_C2 bytes"
    echo "Public inputs: $PUB_INPUT_SIZE_C2 bytes"
    echo ""
    echo "This demonstrates Stellar's current protocol limits for"
    echo "computationally expensive ZK proof verification."
    echo "═══════════════════════════════════════"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "SUMMARY"
echo "════════════════════════════════════════════════════════════"
echo "Both circuits deployed successfully:"
echo "  1. Merkle Root: $CID_MERKLE"
echo "  2. Position Movement: $CID_MOVEMENT"
echo ""
echo "Verification on testnet is limited. Solutions:"
echo "  1. Use local network: sh test-local_trap-grid.sh"
echo "  2. Simplify the circuits to reduce CPU requirements"
echo "  3. Wait for Stellar protocol upgrades with higher limits"
echo "════════════════════════════════════════════════════════════"