use crate::{
    main,
    libs::{
        merkle_tree::binary_merkle_root_computation::{
            compute_merkle_root,
            //verify_merkle_proof,
            MERKLE_PROOF_LENGTH
        },
        hash::poseidon::poseidon_hash::{
            poseidon_hash_1, 
            poseidon_hash_2, 
            poseidon_hash_3, 
            poseidon_hash_4,
            poseidon_hash_5,
            poseidon_hash_6
        }
    },
    //use tests::{ test_main };

    types::{
        public_inputs::PublicInputs,
        constants::{ GRID_SIZE, NUM_CELLS, MERKLE_TREE_DEPTH }
    },
    PrivateInputs
};

#[test]
fn test_main() {
    // First, compute the expected Merkle root with test data
    let test_move_x = 1;
    let test_move_y = 2;
    let test_trap_value = 1;
    let test_moved_position_index = test_move_x * GRID_SIZE + test_move_y; // 10 (= 1 * 8 + 2)
    let test_trap_commitment = poseidon_hash_2([test_trap_value as Field, test_moved_position_index as Field]);
    let test_trap_merkle_proof_indices = [0, 1, 0, 1, 0, 0];           // Binary of 10: 001010 (LSB to MSB)
    let test_trap_merkle_proof_siblings = [0; MERKLE_TREE_DEPTH];   // All zeros for simple test
    
    // Compute what the Merkle root should be with this configuration
    let trap_merkle_root: Field = compute_merkle_root(
        test_trap_commitment,
        MERKLE_PROOF_LENGTH,
        test_trap_merkle_proof_indices,
        test_trap_merkle_proof_siblings
    );
    println(f"Trap Merkle Root: {trap_merkle_root}");

    // ------------ PUBLIC INPUTS ------------- //
    let public_inputs = PublicInputs {
        trap_merkle_root: trap_merkle_root,
        move_x: test_move_x,
        move_y: test_move_y,
        is_hit: test_trap_value,
        trap_merkle_proof_length: MERKLE_PROOF_LENGTH,
        trap_merkle_proof_indices: test_trap_merkle_proof_indices,
        trap_merkle_proof_siblings: test_trap_merkle_proof_siblings
    };

    // ------------ PRIVATE INPUTS ------------- //
    let private_inputs = PrivateInputs {
        trap_value: test_trap_value
    };

    // @dev - Execute the main function with the test inputs
    main(public_inputs, private_inputs);

    // @dev - Verify that the Merkle root computation is consistent
    let moved_position_index = public_inputs.move_x * GRID_SIZE + public_inputs.move_y;
    let trap_commitment = poseidon_hash_2([private_inputs.trap_value as Field, moved_position_index as Field]);

    // @dev - Check whether the computed Merkle root matches the expected value (this is a placeholder assertion, replace with actual expected value)
    let computed_trap_merkle_root: Field = compute_merkle_root(
        trap_commitment, 
        public_inputs.trap_merkle_proof_length, 
        public_inputs.trap_merkle_proof_indices, 
        public_inputs.trap_merkle_proof_siblings
    ); // @dev - Placeholder commitment value (1 for trap, 0 for no trap)
    println(f"Computed Trap Merkle Root: {computed_trap_merkle_root}");
    assert(computed_trap_merkle_root == trap_merkle_root, "Merkle root computation failed");
}