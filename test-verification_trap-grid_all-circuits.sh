#!/usr/bin/env bash
set -euo pipefail

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
# 1. trap-grid-merkle-root: Verifies the trap grid merkle root
# 2. trap-grid-position-movement: Verifies position movement and trap detection
# ============================================================================

ROOT="$(cd "$(dirname "$0")" && pwd)"
TRAP_GRID_MERKLE="$ROOT/trap-grid/trap-grid-merkle-root"
TRAP_GRID_MOVEMENT="$ROOT/trap-grid/trap-grid-position-movement"
CONTRACT_DIR="$ROOT/rs-soroban-ultrahonk"

# Load environment variables from .env file
if [ -f "$ROOT/.env" ]; then
    echo "==> Loading .env file"
    source "$ROOT/.env"
fi

echo "==> 0) Clean artifacts"
rm -rf "$TRAP_GRID_MERKLE/target"
rm -rf "$TRAP_GRID_MOVEMENT/target"
rm -rf "$CONTRACT_DIR/target"

# ============================================================================
# CIRCUIT 1: trap-grid-merkle-root
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "CIRCUIT 1: trap-grid-merkle-root"
echo "════════════════════════════════════════════════════════════"

echo "==> 1a) cd $TRAP_GRID_MERKLE"
cd "$TRAP_GRID_MERKLE"

echo "==> 1b) Build circuit + witness"
npm i -D @aztec/bb.js@0.87.0 source-map-support typescript @types/node tsx

echo "==> 1c) TypeScript helpers ready (using tsx)"

nargo compile
nargo execute

echo "==> 1d) Generate UltraHonk (keccak) VK + proof"
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"

node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/trap_grid_merkle_root.json \
  -o ./target/vk.keccak

node "$BBJS" prove_ultra_keccak_honk \
  -b ./target/trap_grid_merkle_root.json \
  -w ./target/trap_grid_merkle_root.gz \
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
# CIRCUIT 2: trap-grid-position-movement
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "CIRCUIT 2: trap-grid-position-movement"
echo "════════════════════════════════════════════════════════════"

echo "==> 2a) cd $TRAP_GRID_MOVEMENT"
cd "$TRAP_GRID_MOVEMENT"

echo "==> 2b) Build circuit + witness"
npm i -D @aztec/bb.js@0.87.0 source-map-support typescript @types/node tsx

echo "==> 2c) TypeScript helpers ready (using tsx)"

nargo compile
nargo execute

echo "==> 2d) Generate UltraHonk (keccak) VK + proof"
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"

node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/trap_grid_position_movement.json \
  -o ./target/vk.keccak

node "$BBJS" prove_ultra_keccak_honk \
  -b ./target/trap_grid_position_movement.json \
  -w ./target/trap_grid_position_movement.gz \
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

echo "==> 5) cd $CONTRACT_DIR"
cd "$CONTRACT_DIR"

echo "==> 5a) Setup source account for testnet"
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

echo "==> 5b) Build contract"
stellar contract build --optimize

# ============================================================================
# DEPLOY AND VERIFY CIRCUIT 1: trap-grid-merkle-root
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "DEPLOY CIRCUIT 1: trap-grid-merkle-root"
echo "════════════════════════════════════════════════════════════"

CID_MERKLE="$(
  stellar contract deploy \
    --wasm target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm \
    --source-account "$SOURCE_ACCOUNT" \
    --network testnet \
    -- \
    --vk_bytes-file-path "$TRAP_GRID_MERKLE/target/vk" \
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
echo "==> 6a) Attempting proof verification for circuit 1 (expected to fail)"
echo "    This demonstrates the protocol limitation..."

VERIFY_OUTPUT_C1=$(stellar contract invoke \
  --id "$CID_MERKLE" \
  --source-account "$SOURCE_ACCOUNT" \
  --network testnet \
  --send yes \
  -- \
  verify_proof \
  --public_inputs-file-path "$TRAP_GRID_MERKLE/target/public_inputs" \
  --proof_bytes-file-path "$TRAP_GRID_MERKLE/target/proof" 2>&1)
VERIFY_EXIT_C1=$?

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
    echo "❌ Circuit 1 verification failed as expected: Budget ExceededLimit"
    echo "═══════════════════════════════════════"
fi

# ============================================================================
# DEPLOY AND VERIFY CIRCUIT 2: trap-grid-position-movement
# ============================================================================
echo ""
echo "════════════════════════════════════════════════════════════"
echo "DEPLOY CIRCUIT 2: trap-grid-position-movement"
echo "════════════════════════════════════════════════════════════"

CID_MOVEMENT="$(
  stellar contract deploy \
    --wasm target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm \
    --source-account "$SOURCE_ACCOUNT" \
    --network testnet \
    -- \
    --vk_bytes-file-path "$TRAP_GRID_MOVEMENT/target/vk" \
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
echo "==> 6b) Attempting proof verification for circuit 2 (expected to fail)"
echo "    This demonstrates the protocol limitation..."

VERIFY_OUTPUT_C2=$(stellar contract invoke \
  --id "$CID_MOVEMENT" \
  --source-account "$SOURCE_ACCOUNT" \
  --network testnet \
  --send yes \
  -- \
  verify_proof \
  --public_inputs-file-path "$TRAP_GRID_MOVEMENT/target/public_inputs" \
  --proof_bytes-file-path "$TRAP_GRID_MOVEMENT/target/proof" 2>&1)
VERIFY_EXIT_C2=$?

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
    echo "❌ Circuit 2 verification failed as expected: Budget ExceededLimit"
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