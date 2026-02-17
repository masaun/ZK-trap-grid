use crate::{
    libs::{
        merkle_tree::binary_merkle_root_computation::{
            MERKLE_PROOF_LENGTH, MERKLE_TREE_DEPTH
        }
    },
    types::constants::{ GRID_SIZE, NUM_CELLS, TREE_DEPTH }
};

/**
 * @notice - Struct to hold all public inputs for the trap grid game
 * @param trap_merkle_root - The commitment to hidden grid (Merkle root of the trap grid)
 * @param move_x - The x-coordinate of the move
 * @param move_y - The y-coordinate of the move
 * @param is_hit - The claimed result of the move (1 for hit, 0 for miss)
 * @param trap_merkle_proof_length - The length of the Merkle proof for the trap value at the move coordinates
 * @param trap_merkle_proof_indices - The indices for the Merkle proof (indicating left/right child at each level)
 * @param trap_merkle_proof_siblings - The sibling nodes for the Merkle proof
 */
pub struct PublicInputs {
    pub trap_merkle_root: Field, // @dev - Merkle root of the trap grid
    pub move_x: u32,
    pub move_y: u32,
    pub is_hit: u32,
    pub trap_merkle_proof_length: u32,
    pub trap_merkle_proof_indices: [u1; MERKLE_TREE_DEPTH],
    pub trap_merkle_proof_siblings: [Field; MERKLE_TREE_DEPTH]
}