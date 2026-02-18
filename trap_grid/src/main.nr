mod libs;
mod types;
mod tests;

use libs::{
    merkle_tree::binary_merkle_root_computation::{
        compute_merkle_root,
        //verify_merkle_proof
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
    constants::{ GRID_SIZE, NUM_CELLS, MERKLE_TREE_DEPTH }
};

// @dev - Private inputs struct
pub struct PrivateInputs {
    trap_value: u32 // @dev - 0 for no trap, 1 for trap
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
    let trap_merkle_proof_length: u32 = public_inputs.trap_merkle_proof_length;  // @dev - [Key Point]: The MERKLE_PROOF_LENGTH would always be equal to the MERKLE_TREE_DEPTH for a binary Merkle tree, since each level of the tree contributes one sibling node to the proof. Therefore, we can set MERKLE_PROOF_LENGTH to be equal to MERKLE_TREE_DEPTH.
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
    assert(trap_value == is_hit, "Claimed hit/miss does not match trap value");  // @dev - "trap_value" is also used used for the trap_merkle_root computation as a "leaf" value at the subsequent line in this circuit. Thereby, this constraint can check whether a given "is_hit" is truly consistent with the actual trap value at the move coordinates, which is a critical constraint to ensure the integrity of the game logic. If this assertion fails, it means that the player is claiming a hit/miss that does not align with the actual trap configuration, which would be a violation of the game's rules.

    // 4-1. Compute a moved_position_index = x * 8 + y
    let moved_position_index = move_x * GRID_SIZE + move_y; // @dev - [NOTE]: A "movement index" can also be a "leaf index".

    // 8x8 Grid
    // --------------------------------
    // (0,0) -> 0
    // (0,1) -> 1
    // ...
    // (1,0) -> 8
    // ...
    // (7,7) -> 63
    // --------------------------------
    //
    // moved_position_index = x * 8 + y
    //
    // NOTE: As you can see above, in case of 8x8 Grid, the range of movement: (0,63)

    // 4-2. Reconstruct a moved_position_index from a given trap merkle proof indices, which is come from a public input.
    let mut reconstructed_moved_position_index: u32 = 0;
    for i in 0..MERKLE_TREE_DEPTH {
        reconstructed_moved_position_index += (trap_merkle_proof_indices[i] as u32) << i;
    }

    // 4-3. Assert that the reconstructed moved_position_index from the proof matches the expected moved_position_index based on the move coordinates. This ensures that the Merkle proof provided is indeed for the correct leaf corresponding to the move being verified.
    assert(reconstructed_moved_position_index == moved_position_index);

    // 5-1: Compute a trap commitment by hashing the trap value with the moved position index. This commitment represents the specific trap configuration at the move coordinates and will be used as the leaf value for Merkle proof verification.
    let trap_commitment = poseidon_hash_2([trap_value as Field, moved_position_index as Field]);

    // 5-2. Verify Merkle inclusion (by comparing an computed merkle root with a given merkle root)
    let computed_trap_merkle_root = compute_merkle_root(
        trap_commitment, // @dev - A hashed "trap_value" would be used as a "leaf" value for the Trap Merkle Proof verification, since the Merkle tree is built on top of the trap values (0 or 1) at each cell. By using the actual "trap_value" as the leaf input to the Merkle root computation, we can directly verify whether this specific trap value is correctly included in the committed trap grid (represented by the public "trap_merkle_root"). This is a critical step to ensure that the player's claimed hit/miss result is consistent with their original commitment to the trap grid configuration. If the computed Merkle root matches the public Merkle root, it confirms that the provided trap value at the move coordinates is indeed part of the committed trap grid, thereby validating the player's claim for that move.
        //trap_value as Field, // @dev - [Key Point]: A hashed "trap_value" would be used as a "leaf" value for the Trap Merkle Proof verification, since the Merkle tree is built on top of the trap values (0 or 1) at each cell. By using the actual "trap_value" as the leaf input to the Merkle root computation, we can directly verify whether this specific trap value is correctly included in the committed trap grid (represented by the public "trap_merkle_root"). This is a critical step to ensure that the player's claimed hit/miss result is consistent with their original commitment to the trap grid configuration. If the computed Merkle root matches the public Merkle root, it confirms that the provided trap value at the move coordinates is indeed part of the committed trap grid, thereby validating the player's claim for that move.
        trap_merkle_proof_length,  // @dev - [Key Point]: The MERKLE_PROOF_LENGTH would always be equal to the MERKLE_TREE_DEPTH for a binary Merkle tree, since each level of the tree contributes one sibling node to the proof. Therefore, we can set MERKLE_PROOF_LENGTH to be equal to MERKLE_TREE_DEPTH.
        trap_merkle_proof_indices,
        trap_merkle_proof_siblings
    );
    assert(computed_trap_merkle_root == trap_merkle_root, "Invalid Merkle proof: a computed root does not match a given public trap root");
}

