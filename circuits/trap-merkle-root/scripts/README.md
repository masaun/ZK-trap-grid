# Trap Grid Helper Scripts

This directory contains TypeScript helper scripts for the trap grid ZK circuit.

## Files

### TypeScript Source Files (in `helpers/`)

1. **count_pub_inputs.ts** - Counts the number of public input fields from the circuit ABI
2. **build_public_inputs.ts** - Builds the public_inputs binary file from Prover.toml
3. **generate_test_data.ts** - Generates valid test data with Merkle proofs for Prover.toml

### JavaScript Output Files (in `helpers/`)

The TypeScript files are compiled to JavaScript using the TypeScript compiler. The compiled `.js` files are used by the shell scripts.

## Setup

The main test scripts automatically install dependencies and compile TypeScript:

```bash
npm i -D @aztec/bb.js@0.87.0 source-map-support typescript @types/node
cd scripts && npx tsc && cd ..
```

## Manual Compilation

To manually compile the TypeScript files:

```bash
cd scripts
npx tsc
```

This will compile all `.ts` files in the `helpers/` directory to JavaScript.

## Usage

### Generate Test Data

```bash
cd trap_grid
node scripts/helpers/generate_test_data.js [move_x] [move_y]
```

Or directly with TypeScript (requires tsx):
```bash
npx tsx scripts/helpers/generate_test_data.ts [move_x] [move_y]
```

Example:
```bash
node scripts/helpers/generate_test_data.js 0 0
```

This will generate valid Merkle proof data for the specified grid position.

### Count Public Inputs

```bash
node scripts/helpers/count_pub_inputs.js
```

Returns the number of public input fields (should be 17 for trap_grid).

### Build Public Inputs Binary

```bash
node scripts/helpers/build_public_inputs.js
```

Reads `Prover.toml` and generates the binary `target/public_inputs` file.

## TypeScript Configuration

The `tsconfig.json` file configures the TypeScript compiler with:
- Target: ES2020
- Module: CommonJS
- Strict type checking enabled
- JSON import support for reading circuit ABI

## Dependencies

- `typescript` - TypeScript compiler
- `@types/node` - Node.js type definitions
- `poseidon-lite` - For Poseidon hash computation (in generate_test_data.ts)

## Type Safety

The TypeScript versions provide:
- Type-safe interfaces for circuit ABI structures
- Type-safe TOML parsing
- Proper type annotations for all functions
- Better IDE support and auto-completion
