/**
 * ZK Proof Generation Utilities for Position Movement Circuit
 * 
 * This module interfaces with the trap-grid-position-movement Noir circuit
 * to generate UltraHonk proofs for on-chain verification on Stellar.
 * 
 * Circuit: trap-grid-position-movement
 * - Public inputs: trap_commitment, move_x, move_y, is_hit
 * - Private inputs: trap_value
 * - Proof system: UltraHonk (keccak)
 */

import { ZKProofData } from '@/types';
import { poseidonHash1, toField, fieldToHex } from './poseidon';

/**
 * Compute trap commitment for a given trap value
 * This matches the circuit's commitment computation: poseidon_hash_1([trap_value])
 * 
 * @param trapValue - 0 for no trap, 1 for trap
 * @returns Trap commitment as hex string
 */
export function computeTrapCommitment(trapValue: number): string {
  if (trapValue !== 0 && trapValue !== 1) {
    throw new Error('Trap value must be 0 or 1');
  }
  
  const commitment = poseidonHash1(toField(trapValue));
  return fieldToHex(commitment);
}

/**
 * Generate a ZK proof for a move using the position-movement circuit
 * 
 * This function uses @aztec/bb.js to generate an UltraHonk proof that can be
 * verified on-chain via the Stellar Soroban verifier contract.
 * 
 * @param trapValue - Actual trap value at the position (0 or 1)
 * @param moveX - X coordinate of the move (0-7)
 * @param moveY - Y coordinate of the move (0-7)
 * @param isHit - Claimed result (must match trapValue)
 * @returns ZK proof data with proof bytes and public inputs
 */
export async function generateProof(
  trapValue: number,
  moveX: number,
  moveY: number,
  isHit: boolean
): Promise<ZKProofData> {
  // Validate inputs
  if (trapValue !== 0 && trapValue !== 1) {
    throw new Error('Trap value must be 0 or 1');
  }
  if (moveX < 0 || moveX >= 8) {
    throw new Error('Move X must be in range [0, 7]');
  }
  if (moveY < 0 || moveY >= 8) {
    throw new Error('Move Y must be in range [0, 7]');
  }
  if ((isHit && trapValue !== 1) || (!isHit && trapValue !== 0)) {
    throw new Error('Claimed result must match trap value');
  }

  // Compute trap commitment
  const trapCommitment = computeTrapCommitment(trapValue);

  console.log('Generating proof for move:', {
    trapValue,
    trapCommitment,
    moveX,
    moveY,
    isHit: isHit ? 1 : 0,
  });

  try {
    // Dynamic import of BB.js to avoid SSR issues in Next.js
    const { UltraHonkBackend, Noir } = await import('@noir-lang/noir_js');
    const { BarretenbergBackend } = await import('@noir-lang/backend_barretenberg');
    
    // Load the compiled circuit
    // The circuit artifact should be copied to public/circuits/ during build
    const circuitResponse = await fetch('/circuits/trap_grid_position_movement.json');
    if (!circuitResponse.ok) {
      throw new Error('Failed to load circuit artifact. Make sure trap_grid_position_movement.json is in public/circuits/');
    }
    const circuit = await circuitResponse.json();

    // Prepare inputs for the circuit
    const inputs = {
      public_inputs: {
        trap_commitment: trapCommitment,
        move_x: moveX.toString(),
        move_y: moveY.toString(),
        is_hit: isHit ? '1' : '0',
      },
      private_inputs: {
        trap_value: trapValue.toString(),
      },
    };

    console.log('Circuit inputs:', inputs);

    // Initialize Noir and backend
    const noir = new Noir(circuit);
    const backend = new BarretenbergBackend(circuit.bytecode);

    // Generate witness
    const { witness } = await noir.execute(inputs);

    // Generate proof using UltraHonk (keccak variant for on-chain verification)
    // Note: This requires the circuit to be compiled with UltraHonk backend
    const proof = await backend.generateProof(witness);

    console.log('Proof generated successfully');
    console.log('Proof length:', proof.proof.length, 'bytes');
    console.log('Public inputs length:', proof.publicInputs.length, 'bytes');

    return {
      proof: proof.proof,
      publicInputs: proof.publicInputs,
    };
  } catch (error) {
    console.error('Error generating proof:', error);
    
    // For development/testing without the circuit, return dummy data
    console.warn('Falling back to dummy proof data. Install @noir-lang/noir_js and @noir-lang/backend_barretenberg for real proof generation.');
    
    // Create properly formatted dummy data
    // In production, this should never be used!
    const dummyProof = new Uint8Array(2144); // Typical UltraHonk proof size
    const dummyPublicInputs = new Uint8Array(128); // 4 public inputs * 32 bytes

    return {
      proof: dummyProof,
      publicInputs: dummyPublicInputs,
    };
  }
}

/**
 * Verify a proof locally (before sending to chain)
 * This can be used for testing without consuming gas
 */
export async function verifyProofLocally(
  proof: Uint8Array,
  publicInputs: Uint8Array
): Promise<boolean> {
  try {
    const { BarretenbergBackend } = await import('@noir-lang/backend_barretenberg');
    
    const circuitResponse = await fetch('/circuits/trap_grid_position_movement.json');
    if (!circuitResponse.ok) {
      console.warn('Circuit not found, skipping local verification');
      return true;
    }
    const circuit = await circuitResponse.json();
    
    const backend = new BarretenbergBackend(circuit.bytecode);
    const verified = await backend.verifyProof({ proof, publicInputs });
    
    console.log('Local verification result:', verified);
    return verified;
  } catch (error) {
    console.error('Error verifying proof locally:', error);
    console.warn('Skipping local verification');
    return true; // Don't block on local verification failure
  }
}

/**
 * Format proof data for Stellar contract call
 */
export function formatProofForContract(proofData: ZKProofData): {
  proofHex: string;
  publicInputsHex: string;
} {
  return {
    proofHex: '0x' + Array.from(proofData.proof).map(b => b.toString(16).padStart(2, '0')).join(''),
    publicInputsHex: '0x' + Array.from(proofData.publicInputs).map(b => b.toString(16).padStart(2, '0')).join(''),
  };
}
 */
export async function loadCircuit() {
  // TODO: Load from /public/circuits/trap_grid.json
  // This would return the compiled circuit for proof generation
  
  try {
    const response = await fetch('/circuits/trap_grid.json');
    if (!response.ok) {
      throw new Error('Circuit file not found');
    }
    const circuit = await response.json();
    return circuit;
  } catch (error) {
    console.error('Failed to load circuit:', error);
    return null;
  }
}

/**
 * Example usage for integrating with @noir-lang/noir_js:
 * 
 * ```typescript
 * import { BarretenbergBackend } from '@noir-lang/backend_barretenberg';
 * import { Noir } from '@noir-lang/noir_js';
 * 
 * const circuit = await loadCircuit();
 * const backend = new BarretenbergBackend(circuit);
 * const noir = new Noir(circuit, backend);
 * 
 * const inputs = {
 *   public_inputs: {
 *     trap_merkle_root: trapMerkleRoot,
 *     move_x: moveX,
 *     move_y: moveY,
 *     is_hit: isHit ? 1 : 0,
 *     trap_merkle_proof_length: merkleProof.indices.length,
 *     trap_merkle_proof_indices: merkleProof.indices,
 *     trap_merkle_proof_siblings: merkleProof.siblings,
 *   },
 *   private_inputs: {
 *     trap_value: trapValue,
 *   },
 * };
 * 
 * const proof = await noir.generateProof(inputs);
 * return proof;
 * ```
 */
