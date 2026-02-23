use crate::{
    libs::{
        merkle_tree::binary_merkle_root_computation::{
            MERKLE_PROOF_LENGTH
        }
    },
    types::constants::{ GRID_SIZE, NUM_CELLS, MERKLE_TREE_DEPTH }
};

/**
 * @notice - Struct to hold all public inputs for the trap grid game
 * @param trap_commitment - The Poseidon hash commitment of the trap configuration at the move coordinates. This is computed as poseidon_hash_2([trap_value, secret]) where trap_value is 1 for a trap and 0 for no trap, and secret is a random value to ensure commitment uniqueness.
 */
pub struct PublicInputs {
    pub trap_commitment: Field
}