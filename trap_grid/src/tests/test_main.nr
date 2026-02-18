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
    // @dev - A given Trap Merkle Root, which is stored by a player as a commitment to their trap grid (this is a placeholder value, replace with actual commitment value) 
    let trap_merkle_root: Field = 0x1f043a4524fc107a4021d837cc83206234f0e79cb59de08dc4e16800627a4329; // @dev - Placeholder commitment value (1 for trap, 0 for no trap)
    println(f"Trap Merkle Root: {trap_merkle_root}");

    // ------------ PUBLIC INPUTS ------------- //
    let public_inputs = PublicInputs {
        trap_merkle_root: trap_merkle_root,
        move_x: 1,
        move_y: 2,
        is_hit: 1,
        trap_merkle_proof_length: MERKLE_PROOF_LENGTH, // @dev - Placeholder value, replace with actual proof length
        trap_merkle_proof_indices: [0; MERKLE_TREE_DEPTH], // @dev - Placeholder values, replace with actual proof indices
        trap_merkle_proof_siblings: [0; MERKLE_TREE_DEPTH] // @dev - Placeholder values, replace with actual proof
    };

    // ------------ PRIVATE INPUTS ------------- //
    let private_inputs = PrivateInputs {
        trap_value: 1 // @dev - Placeholder value (1 for trap, 0 for no trap)
    };

    // @dev - Execute the main function with the test inputs
    main(public_inputs, private_inputs);

    // @dev - Check whether the computed Merkle root matches the expected value (this is a placeholder assertion, replace with actual expected value)
    let computed_trap_merkle_root: Field = compute_merkle_root(
        1, 
        MERKLE_PROOF_LENGTH, 
        [0; MERKLE_TREE_DEPTH], 
        [0; MERKLE_TREE_DEPTH]
    ); // @dev - Placeholder commitment value (1 for trap, 0 for no trap)
    println(f"Computed Trap Merkle Root: {computed_trap_merkle_root}");
    assert(computed_trap_merkle_root == trap_merkle_root, "Merkle root computation failed");
}