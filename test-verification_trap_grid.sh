#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Trap Grid ZK Circuit - Stellar Testnet Verification Script
# ============================================================================
# ⚠️  KNOWN LIMITATION: The trap_grid circuit verification EXCEEDS Stellar 
# testnet's hard CPU instruction limit (~100M instructions per transaction).
# 
# This script will successfully deploy the contract but FAIL at verification
# with: "HostError: Error(Budget, ExceededLimit)"
#
# This is a protocol-level constraint that CANNOT be bypassed with higher fees.
#
# ✅ USE LOCAL NETWORK INSTEAD:
#   sh test-local_trap-grid.sh
#
# The local network runs with --limits unlimited and successfully verifies
# complex ZK proofs like trap_grid.
#
# This script is kept for reference and testing simpler circuits on testnet.
# ============================================================================

ROOT="$(cd "$(dirname "$0")" && pwd)"
TRAP_GRID="$ROOT/trap_grid"
CONTRACT_DIR="$ROOT/rs-soroban-ultrahonk"

# Load environment variables from .env file
if [ -f "$ROOT/.env" ]; then
    echo "==> Loading .env file"
    source "$ROOT/.env"
fi

echo "==> 0) Clean artifacts"
rm -rf "$TRAP_GRID/target"
rm -rf "$CONTRACT_DIR/target"

echo "==> 1) cd $TRAP_GRID"
cd "$TRAP_GRID"

echo "==> 2) Build circuit + witness"
npm i -D @aztec/bb.js@0.87.0 source-map-support
nargo compile
nargo execute

echo "==> 3) Generate UltraHonk (keccak) VK + proof"
BBJS="./node_modules/@aztec/bb.js/dest/node/main.js"

node "$BBJS" write_vk_ultra_keccak_honk \
  -b ./target/trap_grid.json \
  -o ./target/vk.keccak

node "$BBJS" prove_ultra_keccak_honk \
  -b ./target/trap_grid.json \
  -w ./target/trap_grid.gz \
  -o ./target/proof.with_public_inputs

echo "==> 4) Split proof into public_inputs + proof bytes"
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

echo "==> 5b) Build + deploy contract with VK bytes"
stellar contract build --optimize

CID="$(
  stellar contract deploy \
    --wasm target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm \
    --source-account "$SOURCE_ACCOUNT" \
    --resource-fee 100000000 \
    --network testnet \
    -- \
    --vk_bytes-file-path "$TRAP_GRID/target/vk" \
  | tail -n1
)"

echo "==> Deployed CID: $CID"

echo "==> 6) Verify proof (simulation, --send no) on Stellar Testnet"
stellar contract invoke \
  --id "$CID" \
  --source-account "$SOURCE_ACCOUNT" \
  --network testnet \
  --resource-fee 100000000 \
  --send no \
  -- \
  verify_proof \
  --public_inputs-file-path "$TRAP_GRID/target/public_inputs" \
  --proof_bytes-file-path "$TRAP_GRID/target/proof"

echo "==> 7) Verify proof on-chain (--send yes) on Stellar Testnet"
stellar contract invoke \
  --id "$CID" \
  --source-account "$SOURCE_ACCOUNT" \
  --network testnet \
  --resource-fee 100000000 \
  --send yes \
  -- \
  verify_proof \
  --public_inputs-file-path "$TRAP_GRID/target/public_inputs" \
  --proof_bytes-file-path "$TRAP_GRID/target/proof"

echo "==> Done! On-chain verification succeeded. (on Stellar Testnet)"