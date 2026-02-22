#!/usr/bin/env node

/**
 * Helper script to generate valid test data for trap_grid Prover.toml
 * 
 * This script creates a simple trap grid configuration and computes the
 * Merkle tree with valid proofs that can be used for testing.
 * 
 * Usage: ts-node generate_test_data.ts [move_x] [move_y]
 *        or with tsx: tsx generate_test_data.ts [move_x] [move_y]
 */

import { poseidon1, poseidon2 } from 'poseidon-lite';

// Constants from the circuit
const GRID_SIZE = 8;
const NUM_CELLS = 64;
const MERKLE_TREE_DEPTH = 6;

interface TrapPosition {
  x: number;
  y: number;
}

interface MerkleProof {
  indices: number[];
  siblings: bigint[];
}

/**
 * Compute Poseidon hash of two field elements
 * Using poseidon2 from poseidon-lite which matches Noir's poseidon_hash_2
 */
function poseidonHash2(left: bigint | number, right: bigint | number): bigint {
  // poseidon-lite expects inputs as bigints or numbers
  const leftBigInt = typeof left === 'bigint' ? left : BigInt(left);
  const rightBigInt = typeof right === 'bigint' ? right : BigInt(right);

  // poseidon2 returns a bigint
  return poseidon2([leftBigInt, rightBigInt]);
}

/**
 * Generate a simple trap grid (all zeros except specified traps)
 */
function generateTrapGrid(traps: TrapPosition[] = []): number[] {
  const grid = new Array(NUM_CELLS).fill(0);
  for (const { x, y } of traps) {
    const index = x * GRID_SIZE + y;
    grid[index] = 1;
  }
  return grid;
}

/**
 * Compute trap commitment for a given cell
 * Using poseidon1 to match the circuit: poseidon_hash_1([trap_value as Field])
 */
function computeTrapCommitment(trapValue: number, leafIndex: number): bigint {
  // Match the circuit which uses: poseidon_hash_1([trap_value as Field])
  return poseidon1([BigInt(trapValue)]);
}

/**
 * Build Merkle tree from trap commitments
 */
function buildMerkleTree(grid: number[]): bigint[][] {
  // Level 0: Compute commitments for all leaves
  let currentLevel: bigint[] = grid.map((trap, idx) =>
    computeTrapCommitment(trap, idx)
  );

  const tree: bigint[][] = [currentLevel];

  // Build tree bottom-up
  for (let level = 0; level < MERKLE_TREE_DEPTH; level++) {
    const nextLevel: bigint[] = [];
    for (let i = 0; i < currentLevel.length; i += 2) {
      const left = currentLevel[i];
      const right = currentLevel[i + 1] || left; // Duplicate if odd number
      nextLevel.push(poseidonHash2(left, right));
    }
    tree.push(nextLevel);
    currentLevel = nextLevel;
  }

  return tree;
}

/**
 * Generate Merkle proof for a specific leaf
 */
function generateMerkleProof(tree: bigint[][], leafIndex: number): MerkleProof {
  const siblings: bigint[] = [];
  const indices: number[] = [];
  let currentIndex = leafIndex;

  for (let level = 0; level < MERKLE_TREE_DEPTH; level++) {
    const isRightChild = currentIndex % 2 === 1;
    const siblingIndex = isRightChild ? currentIndex - 1 : currentIndex + 1;

    indices.push(isRightChild ? 1 : 0);
    siblings.push(tree[level][siblingIndex] || tree[level][currentIndex]);

    currentIndex = Math.floor(currentIndex / 2);
  }

  return { indices, siblings };
}

/**
 * Convert BigInt to hex string (32 bytes, big-endian)
 */
function bigIntToHex(value: bigint | number): string {
  const bigIntValue = typeof value === 'bigint' ? value : BigInt(value);
  // Convert to hex and left-pad to 64 characters (32 bytes)
  const hex = bigIntValue.toString(16).padStart(64, '0');
  return '0x' + hex;
}

/**
 * Main function
 */
function main(): void {
  const moveX = parseInt(process.argv[2] || '0');
  const moveY = parseInt(process.argv[3] || '0');

  if (moveX < 0 || moveX >= GRID_SIZE || moveY < 0 || moveY >= GRID_SIZE) {
    console.error(`Error: Move coordinates must be in range [0, ${GRID_SIZE - 1}]`);
    process.exit(1);
  }

  const leafIndex = moveX * GRID_SIZE + moveY;

  // Generate a simple test grid (you can modify this)
  // For testing, let's put a trap at position (0, 0) and (1, 2)
  const traps: TrapPosition[] = [
    { x: 0, y: 0 },
    { x: 1, y: 2 }
  ];

  const grid = generateTrapGrid(traps);
  const tree = buildMerkleTree(grid);
  const root = tree[tree.length - 1][0];
  const proof = generateMerkleProof(tree, leafIndex);

  const trapValue = grid[leafIndex];
  const isHit = trapValue;

  console.log('\n' + '='.repeat(70));
  console.log('Generated Test Data for Trap Grid');
  console.log('='.repeat(70));
  console.log(`\nMove: (${moveX}, ${moveY}) -> Leaf Index: ${leafIndex}`);
  console.log(`Trap Value: ${trapValue} (${trapValue === 1 ? 'HIT' : 'MISS'})`);
  console.log(`\nMerkle Root: ${bigIntToHex(root)}`);
  console.log(`\nProver.toml format:\n`);
  console.log('[public_inputs]');
  console.log(`trap_merkle_root = "${bigIntToHex(root)}"`);
  console.log(`move_x = "${moveX}"`);
  console.log(`move_y = "${moveY}"`);
  console.log(`is_hit = "${isHit}"`);
  console.log(`trap_merkle_proof_length = "${MERKLE_TREE_DEPTH}"`);
  console.log(`trap_merkle_proof_indices = [${proof.indices.map(i => `"${i}"`).join(', ')}]`);
  console.log(`trap_merkle_proof_siblings = [`);
  proof.siblings.forEach((s, i) => {
    console.log(`    "${bigIntToHex(s)}"${i < proof.siblings.length - 1 ? ',' : ''}`);
  });
  console.log(`]`);
  console.log(`\n[private_inputs]`);
  console.log(`trap_value = "${trapValue}"`);
  console.log('\n' + '='.repeat(70));
  console.log('\nCopy the above to trap_grid/Prover.toml to use for testing.');
  console.log('='.repeat(70) + '\n');
}

// Check if required module is available
try {
  main();
} catch (error) {
  if (error instanceof Error && error.message.includes('poseidon-lite')) {
    console.error('\n❌ Error: poseidon-lite not found');
    console.error('Please run: npm install poseidon-lite@0.3.0');
    console.error('\nError details:', error.message);
    process.exit(1);
  }
  throw error;
}
