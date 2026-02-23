mod libs;
mod types;
mod tests;

use types::{
    public_inputs::PublicInputs,
    constants::{ GRID_SIZE }
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
    assert(trap_value == is_hit, "Claimed hit/miss does not match trap value");
}