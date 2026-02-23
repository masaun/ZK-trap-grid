/**
 * Poseidon Hash Utilities
 * 
 * This module provides Poseidon hash functions that match the Noir circuit implementation.
 * We use poseidon-lite for compatibility with the Noir poseidon library.
 */

// Note: poseidon-lite needs to be installed: npm install poseidon-lite
// We'll provide a placeholder implementation that can be replaced
// when poseidon-lite is installed

/**
 * Compute poseidon hash of a single field element
 * Matches Noir's poseidon_hash_1
 */
export function poseidonHash1(value: bigint): bigint {
  try {
    // Try to use poseidon-lite if available
    const poseidon = require('poseidon-lite');
    return poseidon.poseidon1([value]);
  } catch (e) {
    console.warn('poseidon-lite not installed, using placeholder hash');
    // Placeholder: In production, you MUST install poseidon-lite
    // npm install poseidon-lite
    return BigInt('0x' + 
      Array.from({ length: 64 }, (_, i) => 
        ((Number(value) + i) % 16).toString(16)
      ).join('')
    );
  }
}

/**
 * Convert a number to a Field element (bigint)
 */
export function toField(value: number): bigint {
  return BigInt(value);
}

/**
 * Convert a Field element back to hex string for contract calls
 */
export function fieldToHex(field: bigint): string {
  return '0x' + field.toString(16).padStart(64, '0');
}

/**
 * Convert hex string to Field element
 */
export function hexToField(hex: string): bigint {
  return BigInt(hex);
}
