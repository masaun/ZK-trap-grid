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
    secret: Field,    // @dev - A secret value used in the commitment to prevent preimage attacks
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

    // ------------ PRIVATE INPUTS ------------- //
    let trap_value: u32 = private_inputs.trap_value; // @dev - Trap value at the move coordinates (0 or 1)
    let secret: Field = private_inputs.secret; // @dev - Secret value for commitment

    // 4-1: Compute a trap commitment by hashing the trap value with the moved position index. This commitment represents the specific trap configuration at the move coordinates and will be used as the leaf value for Merkle proof verification.
    let computed_trap_commitment = poseidon_hash_2([trap_value as Field, secret]);

    // 4-2. Constraint: Verify that the computed trap commitment matches the public trap commitment
    assert(computed_trap_commitment == trap_commitment, "Invalid commitment: computed commitment does not match public commitment");
}