mod libs;
mod types;
mod tests;

use libs::{
    hash::poseidon::poseidon_hash::{
        poseidon_hash_1, 
        poseidon_hash_2, 
        poseidon_hash_3, 
        poseidon_hash_4,
        poseidon_hash_5,
        poseidon_hash_6
    }
};
use tests::{ test_main };

use types::{
    public_inputs::PublicInputs,
    constants::{ GRID_SIZE, NUM_CELLS, MERKLE_TREE_DEPTH }
};

// @dev - Private inputs struct
pub struct PrivateInputs {
    trap_value: u32,  // @dev - 0 for no trap, 1 for trap
}

/**
 * @notice - Main function to verify a move in the trap grid game
 * @param public_inputs - Contains the Merkle root, move coordinates, hit/miss claim, and Merkle proof
 * @param private_inputs - Contains the actual trap value at the move coordinates (0 or 1)
 */
fn main(
    public_inputs: pub PublicInputs,
    private_inputs: PrivateInputs
) {
    // ------------ PUBLIC INPUTS ------------- //
    let trap_commitment: Field = public_inputs.trap_commitment;
    let move_x: u32 = public_inputs.move_x;
    let move_y: u32 = public_inputs.move_y;
    let is_hit: u32 = public_inputs.is_hit;

    // ------------ PRIVATE INPUTS ------------- //
    let trap_value: u32 = private_inputs.trap_value; // @dev - Trap value at the move coordinates (0 or 1)

    // 1. Constraint: Validate coordinates are within grid
    assert(move_x >= 0);
    assert(move_x < GRID_SIZE);
    assert(move_y >= 0);
    assert(move_y < GRID_SIZE);

    // 2. Constraint: Ensure trap_value is boolean (0 or 1)
    assert((trap_value == 0) | (trap_value == 1), "Trap value must be 0 or 1");

    // 3. Constraint: Ensure claimed result matches actual trap value
    assert(trap_value == is_hit, "Claimed hit/miss does not match trap value");  // @dev - "trap_value" is also used used for the trap_merkle_root computation as a "leaf" value at the subsequent line in this circuit. Thereby, this constraint can check whether a given "is_hit" is truly consistent with the actual trap value at the move coordinates, which is a critical constraint to ensure the integrity of the game logic. If this assertion fails, it means that the player is claiming a hit/miss that does not align with the actual trap configuration, which would be a violation of the game's rules.

    // 4-1: Compute a trap commitment by hashing the trap value with the moved position index. This commitment represents the specific trap configuration at the move coordinates and will be used as the leaf value for Merkle proof verification.
    let computed_trap_commitment = poseidon_hash_1([trap_value as Field]);

    // 4-2. Constraint: Verify that the computed trap commitment matches the public trap commitment
    assert(computed_trap_commitment == trap_commitment, "Invalid commitment: computed commitment does not match public commitment");
}