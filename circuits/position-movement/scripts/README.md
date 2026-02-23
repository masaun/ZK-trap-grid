# Position Movement Helper Scripts

This directory contains TypeScript helper scripts for the position-movement ZK circuit.

## Overview

The position-movement circuit is a simplified circuit that verifies position moves and trap detection without using Merkle proofs. It only validates:
- Move coordinates are within grid bounds
- Trap value is boolean (0 or 1)
- Trap value matches the claimed result

## Files

### TypeScript Source Files (in `helpers/`)

1. **count_pub_inputs.ts** - Counts the number of public input fields from the circuit ABI (should be 3)
2. **build_public_inputs.ts** - Builds the public_inputs binary file from Prover.toml (3 fields: move_x, move_y, is_hit)
3. **generate_test_data.ts** - Generates valid test data for Prover.toml
4. **compute_trap_commitment.ts** - Utility to compute Poseidon hash (legacy, not used in current circuit)

## Setup

The main test scripts automatically install dependencies:

```bash
npm i -D @aztec/bb.js@0.87.0 source-map-support typescript @types/node tsx
```

## Usage

### Generate Test Data

```bash
cd position-movement
npx tsx scripts/helpers/generate_test_data.ts [move_x] [move_y] [trap_value]
```

Example:
```bash
# Generate test data for a hit at position (2, 3)
npx tsx scripts/helpers/generate_test_data.ts 2 3 1

# Generate test data for a miss at position (5, 1)
npx tsx scripts/helpers/generate_test_data.ts 5 1 0
```

This will output properly formatted data that you can copy directly into `Prover.toml`.

### Count Public Inputs

```bash
npx tsx scripts/helpers/count_pub_inputs.ts
```

Returns the number of public input fields (should be 3 for position-movement).

### Build Public Inputs Binary

```bash
npx tsx scripts/helpers/build_public_inputs.ts
```

Reads `Prover.toml` and generates the binary `target/public_inputs` file (96 bytes = 3 fields × 32 bytes).

## TypeScript Configuration

The `tsconfig.json` file configures the TypeScript compiler with:
- Target: ES2020
- Module: CommonJS
- Strict type checking enabled
- JSON import support for reading circuit ABI

## Dependencies

- `typescript` - TypeScript compiler
- `@types/node` - Node.js type definitions
- `tsx` - TypeScript executor
- `@aztec/bb.js` - Aztec proof generation library

## Type Safety

The TypeScript versions provide:
- Type-safe interfaces for circuit ABI structures
- Type-safe TOML parsing
- Proper type annotations for all functions
- Better IDE support and auto-completion

## Public Inputs Format

The position-movement circuit has 3 public input fields:
1. `move_x` (u32) - X-coordinate of the move
2. `move_y` (u32) - Y-coordinate of the move
3. `is_hit` (u32) - Claimed result (0 for miss, 1 for hit)

Each field is 32 bytes, so the total public_inputs file is 96 bytes.
