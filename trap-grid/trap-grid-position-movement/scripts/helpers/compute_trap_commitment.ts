#!/usr/bin/env node

/**
 * Helper script to compute trap commitment for the position-movement circuit
 * 
 * The commitment is computed as: poseidon_hash_1([trap_value])
 * 
 * Usage: ts-node compute_trap_commitment.ts <trap_value>
 */

// Import poseidon from poseidon-lite
import { poseidon1 } from 'poseidon-lite';

// Get command line arguments
const args = process.argv.slice(2);

if (args.length !== 1) {
  console.error('Usage: ts-node compute_trap_commitment.ts <trap_value>');
  console.error('Example: ts-node compute_trap_commitment.ts 0');
  process.exit(1);
}

const trapValue = BigInt(args[0]);

console.log('Computing trap commitment with:');
console.log(`  trap_value: ${trapValue}`);
console.log();

// Use poseidon1 which matches Noir's poseidon_hash_1
const commitment = poseidon1([trapValue]);

console.log('Trap Commitment:');
console.log(`  Decimal: ${commitment}`);
console.log(`  Hex: 0x${commitment.toString(16).padStart(64, '0')}`);
