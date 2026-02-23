#!/usr/bin/env node

/**
 * Helper script to generate valid test data for position-movement Prover.toml
 * 
 * This script creates simple test data for the simplified circuit that verifies:
 * - Move coordinates are within grid bounds
 * - Trap value matches the claimed result (hit/miss)
 * 
 * Usage: ts-node generate_test_data.ts [move_x] [move_y] [trap_value]
 *        or with tsx: tsx generate_test_data.ts [move_x] [move_y] [trap_value]
 * 
 * Example:
 *   tsx generate_test_data.ts 2 3 1  # Generate test data for hit at (2,3)
 *   tsx generate_test_data.ts 5 1 0  # Generate test data for miss at (5,1)
 */

// Constants from the circuit
const GRID_SIZE = 8;

/**
 * Main function
 */
function main(): void {
  const moveX = parseInt(process.argv[2] || '2');
  const moveY = parseInt(process.argv[3] || '3');
  const trapValue = parseInt(process.argv[4] || '1');

  // Validate inputs
  if (moveX < 0 || moveX >= GRID_SIZE || moveY < 0 || moveY >= GRID_SIZE) {
    console.error(`Error: Move coordinates must be in range [0, ${GRID_SIZE - 1}]`);
    process.exit(1);
  }

  if (trapValue !== 0 && trapValue !== 1) {
    console.error('Error: trap_value must be 0 (miss) or 1 (hit)');
    process.exit(1);
  }

  const isHit = trapValue;

  console.log('\n' + '='.repeat(70));
  console.log('Generated Test Data for Position Movement Circuit');
  console.log('='.repeat(70));
  console.log(`\nMove: (${moveX}, ${moveY})`);
  console.log(`Trap Value: ${trapValue} (${trapValue === 1 ? 'HIT' : 'MISS'})`);
  console.log(`Claimed Result (is_hit): ${isHit}`);
  console.log(`\nProver.toml format:\n`);
  console.log('[public_inputs]');
  console.log(`move_x = "${moveX}"`);
  console.log(`move_y = "${moveY}"`);
  console.log(`is_hit = "${isHit}"`);
  console.log(`\n[private_inputs]`);
  console.log(`trap_value = "${trapValue}"`);
  console.log('\n' + '='.repeat(70));
  console.log('\nCopy the above to position-movement/Prover.toml to use for testing.');
  console.log('='.repeat(70) + '\n');
}

main();
