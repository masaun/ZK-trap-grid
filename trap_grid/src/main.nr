mod libs;
mod tests;

use libs::merkle_tree::merkle::verify_merkle_proof;
//use tests::{ test_main };

pub global GRID_SIZE: u32 = 8;
pub global NUM_CELLS: u32 = 64;
pub global TREE_DEPTH: u32 = 6;

/// PUBLIC INPUTS
/// - trap_root
/// - move_x
/// - move_y
/// - is_hit
/// - merkle_path
/// - merkle_indices

fn main(
    // Public inputs
    pub trap_root: Field,
    pub move_x: Field,
    pub move_y: Field,
    pub is_hit: Field,
    pub merkle_path: [Field; TREE_DEPTH],
    pub merkle_indices: [Field; TREE_DEPTH],

    // Private inputs
    trap_value: Field
) {

    // 1. Validate coordinates are within grid
    assert(move_x >= 0);
    assert(move_x < GRID_SIZE);
    assert(move_y >= 0);
    assert(move_y < GRID_SIZE);

    // 2. Ensure trap_value is boolean
    assert(trap_value == 0 || trap_value == 1);

    // 3. Ensure claimed result matches actual trap value
    assert(trap_value == is_hit);

    // 4. Compute leaf index = x * 8 + y
    let leaf_index = move_x * GRID_SIZE + move_y;

    // 5. Verify Merkle inclusion
    let computed_root = verify_merkle_proof(
        trap_value,
        merkle_path,
        merkle_indices
    );

    assert(computed_root == trap_root);
}



