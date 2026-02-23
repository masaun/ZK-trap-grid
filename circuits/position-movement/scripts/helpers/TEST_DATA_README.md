# Position Movement Test Data Generation

## Overview

The `position-movement` circuit is a simplified circuit that verifies:
1. Move coordinates are within grid bounds (0-7 for 8x8 grid)
2. Trap value is boolean (0 or 1)
3. Trap value matches the claimed result (hit/miss)

The circuit does NOT use Merkle proofs or commitments. It only requires simple position and trap value validation.

## Required Data

The `Prover.toml` file needs:

### Public Inputs
- `move_x`: X-coordinate of the move (0-7)
- `move_y`: Y-coordinate of the move (0-7)
- `is_hit`: Claimed result (0 for miss, 1 for hit)

### Private Inputs
- `trap_value`: Actual trap value at the position (0 or 1, must match `is_hit`)

## Solution

### Option 1: Use the Test Data Generator (Recommended)

We've provided a helper script that generates valid test data:

```bash
cd position-movement

# Install dependencies if needed
npm install

# Generate test data for position (x, y) with trap value
# Example: Generate data for a hit at position (2, 3)
npx tsx scripts/helpers/generate_test_data.ts 2 3 1

# Example: Generate data for a miss at position (5, 1)
npx tsx scripts/helpers/generate_test_data.ts 5 1 0
```

The script will output properly formatted data that you can copy directly into `Prover.toml`.

### Option 2: Manual Test Data

You can manually edit `Prover.toml`:

```toml
[public_inputs]
move_x = "2"
move_y = "3"
is_hit = "1"

[private_inputs]
trap_value = "1"
```

Just ensure that `trap_value` equals `is_hit` for a valid proof.

### Option 3: Use the Circuit Tests

The circuit has built-in test cases. Run them with:

```bash
cd position-movement
nargo test --show-output
```

## Running the Full Test Script

Once you have valid data in `Prover.toml`:

```bash
cd scripts/e2e/stellar-testnet
sh test-verification_trap-grid_position-movement-circuit.sh
```

Or for local testing:

```bash
cd position-movement
sh circuit_test.sh
```

The script will:
1. Compile the circuit ✓
2. Generate the witness
3. Generate UltraHonk proof
4. Deploy to Stellar network (if testnet script)
5. Verify the proof on-chain

## Current Status

- Circuit compilation: ✅ Working
- Witness generation: ✅ Working
- Proof generation: ✅ Working
- On-chain verification: ✅ Working (testnet verified!)

## Files

- `Prover.toml` - Test input data
- `generate_test_data.ts` - Helper script to generate valid test data
- `circuit_test.sh` - Run circuit compilation and proof generation
- `test-verification_trap-grid_position-movement-circuit.sh` - Testnet deployment and verification
