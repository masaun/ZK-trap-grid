# Trap Grid Test Data Generation

## Problem

The `trap_grid` circuit requires valid Merkle proof data to generate a witness and create proofs. The `Prover.toml` file needs cryptographically consistent data:

1. A Merkle root that represents the commitment to the trap grid
2. A move position (x, y) within the 8x8 grid
3. A Merkle proof (indices + siblings) proving the trap value at that position
4. The private trap value that matches the claimed hit/miss result

Without valid data, `nargo execute` will fail with "Invalid Merkle proof" error.

## Solution

### Option 1: Use the Test Data Generator (Recommended)

We've provided a helper script that generates valid test data:

```bash
cd trap_grid

# Install dependencies (including poseidon-lite v0.3.0)
npm install

# Generate test data for position (x, y)
# Example: Generate data for position (0, 0)
node generate_test_data.js 0 0

# Example: Generate data for position (1, 2)
node generate_test_data.js 1 2
```

The script will output properly formatted data that you can copy directly into `Prover.toml`.

### Option 2: Use the Circuit Tests

The circuit has built-in test cases with valid data. Run them with:

```bash
cd trap_grid
nargo test --show-output
```

Note: The current tests also use placeholder data and may fail. You'll need to update them with valid Merkle proofs as well.

### Option 3: Build Your Own Test Data

If you want to create custom test data:

1. Define your trap grid (8x8 grid with 0s and 1s)
2. Compute Poseidon hash commitments for each cell: `hash(trap_value, cell_index)`
3. Build a binary Merkle tree from all 64 commitments
4. Extract the Merkle root
5. For your test move position, extract the Merkle proof (6 siblings + 6 indices)
6. Fill in `Prover.toml` with this data

## Running the Full Test Script

Once you have valid data in `Prover.toml`:

```bash
cd ..  # Back to project root
./test-local_trap-grid.sh
```

The script will:
1. Compile the circuit ✓
2. Generate the witness (requires valid Prover.toml)
3. Generate UltraHonk proof
4. Deploy to local Stellar network
5. Verify the proof on-chain

## Current Status

- Circuit compilation: ✅ Working
- Witness generation: ⚠️ Requires valid Prover.toml data
- Proof generation: ⏸️ Requires witness
- On-chain verification: ⏸️ Requires proof

## Files

- `Prover.toml` - Test input data (needs to be updated with valid data)
- `generate_test_data.js` - Helper script to generate valid test data
- `../test-local_trap-grid.sh` - Full end-to-end test script
- `circuit_test.sh` - Run circuit unit tests
