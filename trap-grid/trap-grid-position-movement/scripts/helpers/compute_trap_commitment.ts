#!/usr/bin/env node

/**
 * Helper script to compute trap commitment for the position-movement circuit
 * 
 * The commitment is computed as: poseidon_hash_4([move_x, move_y, trap_value, secret])
 * 
 * Usage: ts-node compute_trap_commitment.ts <move_x> <move_y> <trap_value> <secret>
 */

// Import poseidon from poseidon-lite
import { poseidon4 } from 'poseidon-lite';

// Get command line arguments
const args = process.argv.slice(2);

if (args.length !== 4) {
  console.error('Usage: ts-node compute_trap_commitment.ts <move_x> <move_y> <trap_value> <secret>');
  console.error('Example: ts-node compute_trap_commitment.ts 2 3 0 0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef');
  process.exit(1);
}

const moveX = BigInt(args[0]);
const moveY = BigInt(args[1]);
const trapValue = BigInt(args[2]);
const secret = BigInt(args[3]);

console.log('Computing trap commitment with:');
console.log(`  move_x: ${moveX}`);
console.log(`  move_y: ${moveY}`);
console.log(`  trap_value: ${trapValue}`);
console.log(`  secret: ${secret}`);
console.log();

// Use poseidon4 which matches Noir's poseidon_hash_4
const commitment = poseidon4([moveX, moveY, trapValue, secret]);

console.log('Trap Commitment:');
console.log(`  Decimal: ${commitment}`);
console.log(`  Hex: 0x${commitment.toString(16).padStart(64, '0')}`);
