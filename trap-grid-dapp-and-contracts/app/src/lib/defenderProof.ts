/**
 * Defender Proof Helper
 * 
 * This utility provides functions for defenders to generate ZK proofs
 * in response to attacker moves.
 */

import { generateProof, computeTrapCommitment } from '@/lib/zkProof';
import { getCellIndex } from '@/lib/utils';

export interface StoredTrapGrid {
  trapValues: number[];
}

/**
 * Load trap grid from local storage
 */
export function loadTrapGrid(sessionId: number): StoredTrapGrid | null {
  if (typeof window === 'undefined') return null;
  
  const key = `trap-grid-${sessionId}`;
  const data = localStorage.getItem(key);
  
  if (!data) return null;
  
  try {
    return JSON.parse(data);
  } catch (e) {
    console.error('Failed to parse trap grid data:', e);
    return null;
  }
}

/**
 * Generate proof for a defender response to an attacker's move
 * 
 * @param sessionId - Game session ID
 * @param moveX - X coordinate of the attacker's move
 * @param moveY - Y coordinate of the attacker's move
 * @returns Proof data ready for on-chain submission
 */
export async function generateDefenderProof(
  sessionId: number,
  moveX: number,
  moveY: number
): Promise<{
  proof: Uint8Array;
  publicInputs: Uint8Array;
  isHit: boolean;
  trapCommitment: string;
} | null> {
  // Load trap grid from local storage
  const trapGrid = loadTrapGrid(sessionId);
  
  if (!trapGrid) {
    throw new Error('Trap grid not found. Did you set up traps for this session?');
  }
  
  // Get trap value at the move position
  const cellIndex = getCellIndex(moveX, moveY);
  const trapValue = trapGrid.trapValues[cellIndex];
  
  if (trapValue === undefined) {
    throw new Error('Invalid move coordinates');
  }
  
  // Determine if it's a hit
  const isHit = trapValue === 1;
  
  // Compute trap commitment
  const trapCommitment = computeTrapCommitment(trapValue);
  
  console.log(`Generating proof for move (${moveX}, ${moveY}):`);
  console.log(`  Trap value: ${trapValue}`);
  console.log(`  Is hit: ${isHit}`);
  console.log(`  Commitment: ${trapCommitment}`);
  
  // Generate the ZK proof
  const proofData = await generateProof(
    trapValue,
    moveX,
    moveY,
    isHit
  );
  
  return {
    proof: proofData.proof,
    publicInputs: proofData.publicInputs,
    isHit,
    trapCommitment,
  };
}

/**
 * Get all trap positions for visualization (defender only)
 */
export function getTrapPositions(sessionId: number): Array<{ x: number; y: number }> {
  const trapGrid = loadTrapGrid(sessionId);
  if (!trapGrid) return [];
  
  const positions: Array<{ x: number; y: number }> = [];
  
  for (let x = 0; x < 8; x++) {
    for (let y = 0; y < 8; y++) {
      const index = getCellIndex(x, y);
      if (trapGrid.trapValues[index] === 1) {
        positions.push({ x, y });
      }
    }
  }
  
  return positions;
}

/**
 * Export trap grid for backup (defender only)
 */
export function exportTrapGrid(sessionId: number): string | null {
  const trapGrid = loadTrapGrid(sessionId);
  if (!trapGrid) return null;
  
  return JSON.stringify(trapGrid);
}

/**
 * Import trap grid from backup (defender only)
 */
export function importTrapGrid(sessionId: number, data: string): boolean {
  try {
    const trapGrid = JSON.parse(data);
    
    // Validate the data
    if (!Array.isArray(trapGrid.trapValues)) {
      throw new Error('Invalid trap grid format');
    }
    
    if (trapGrid.trapValues.length !== 64) {
      throw new Error('Trap grid must have 64 values');
    }
    
    for (const value of trapGrid.trapValues) {
      if (value !== 0 && value !== 1) {
        throw new Error('Trap values must be 0 or 1');
      }
    }
    
    // Store in local storage
    const key = `trap-grid-${sessionId}`;
    localStorage.setItem(key, JSON.stringify(trapGrid));
    
    return true;
  } catch (e) {
    console.error('Failed to import trap grid:', e);
    return false;
  }
}
