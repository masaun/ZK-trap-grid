mod libs;
mod types;
mod tests;

use libs::{
    merkle_tree::binary_merkle_root_computation::{
        compute_merkle_root,
        //verify_merkle_proof
        MERKLE_PROOF_LENGTH, MERKLE_TREE_DEPTH
    },
    hash::poseidon::poseidon_hash::{
        poseidon_hash_1, 
        poseidon_hash_2, 
        poseidon_hash_3, 
        poseidon_hash_4,
        poseidon_hash_5,
        poseidon_hash_6
    }
};
//use tests::{ test_main };

use types::{
    public_inputs::PublicInputs,
    constants::{ GRID_SIZE, NUM_CELLS, TREE_DEPTH }
};

// @dev - Private inputs struct
pub struct PrivateInputs {
    trap_value: u32 // @dev - Secret value of Player A (0 for no trap, 1 for trap)
}

/**
 * @notice - Main function to verify a move in the trap grid game
 * @param public_inputs - Contains the Merkle root, move coordinates, hit/miss claim, and Merkle proof
 * @param private_inputs - Contains the actual trap value at the move coordinates (0 or 1)
 */
fn main(
    public_inputs: PublicInputs,
    private_inputs: PrivateInputs
) {
    // ------------ PUBLIC INPUTS ------------- //
    let trap_merkle_root: Field = public_inputs.trap_merkle_root;
    let move_x: u32 = public_inputs.move_x;
    let move_y: u32 = public_inputs.move_y;
    let is_hit: u32 = public_inputs.is_hit;
    let trap_merkle_proof_length: u32 = public_inputs.trap_merkle_proof_length;
    let trap_merkle_proof_indices: [u1; MERKLE_TREE_DEPTH] = public_inputs.trap_merkle_proof_indices;
    let trap_merkle_proof_siblings: [Field; MERKLE_TREE_DEPTH] = public_inputs.trap_merkle_proof_siblings; // @dev - Placeholder, replace with actual siblings from public inputs

    // ------------ PRIVATE INPUTS ------------- //
    let trap_value: u32 = private_inputs.trap_value; // @dev - Secret value of Player A

    // 1. Validate coordinates are within grid
    assert(move_x >= 0);
    assert(move_x < GRID_SIZE);
    assert(move_y >= 0);
    assert(move_y < GRID_SIZE);

    // 2. Ensure trap_value is boolean (0 or 1)
    assert((trap_value == 0) | (trap_value == 1), "Trap value must be 0 or 1"); 

    // 3. Ensure claimed result matches actual trap value
    assert(trap_value == is_hit, "Claimed hit/miss does not match trap value");

    // 4. Compute leaf index = x * 8 + y
    let leaf_index = move_x * GRID_SIZE + move_y;

    // 5. Verify Merkle inclusion (by comparing an computed merkle root with a given merkle root)
    let computed_trap_merkle_root = compute_merkle_root(
        trap_value as Field,
        trap_merkle_proof_length,
        trap_merkle_proof_indices,
        trap_merkle_proof_siblings
    );
    assert(computed_trap_merkle_root == trap_merkle_root, "Invalid Merkle proof: a computed root does not match a given public trap root");
}

