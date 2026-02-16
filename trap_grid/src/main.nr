mod libs;
mod types;
mod tests;

use libs::merkle_tree::merkle::{
    compute_merkle_root,
    //verify_merkle_proof
};
//use tests::{ test_main };

use types::{
    public_inputs::PublicInputs,
    constants::{ GRID_SIZE, NUM_CELLS, TREE_DEPTH }
};

// @dev - Private inputs struct
struct PrivateInputs {
    trap_value: u32
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
    let trap_root: Field = public_inputs.trap_root;
    let move_x: u32 = public_inputs.move_x;
    let move_y: u32 = public_inputs.move_y;
    let is_hit: u32 = public_inputs.is_hit;
    let merkle_path: [Field; TREE_DEPTH] = public_inputs.merkle_path;
    let merkle_indices: [Field; TREE_DEPTH] = public_inputs.merkle_indices;

    // ------------ PRIVATE INPUTS ------------- //
    let trap_value: u32 = private_inputs.trap_value;

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
    let computed_root = compute_merkle_root(trap_value as Field);
    assert(computed_root == trap_root, "Invalid Merkle proof: a computed root does not match a given public trap root");
}

