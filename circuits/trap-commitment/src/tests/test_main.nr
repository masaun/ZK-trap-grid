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
    // @dev - A given Trap commitment, which will be used as the public input for the test. This commitment should correspond to the trap configuration at the move coordinates (1, 2) with a trap value of 1 (indicating a hit). Computed as poseidon_hash_2([1, 12345]).
    let trap_commitment: Field = 0x27cb78d0541f3912c8645bd60acbe7a7205225e0e6f55a17f4843ac719e3eafe;
    println(f"Trap Commitment: {trap_commitment}");

    // ------------ PUBLIC INPUTS ------------- //
    let public_inputs = PublicInputs {
        trap_commitment: trap_commitment
    };

    // ------------ PRIVATE INPUTS ------------- //
    let private_inputs = PrivateInputs {
        trap_value: 1, // @dev - Placeholder value (1 for trap, 0 for no trap)
        secret: 12345 // @dev - Secret value for commitment
    };

    // @dev - Execute the main function with the test inputs
    main(public_inputs, private_inputs);

    // @dev - Check whether the computed trap commitment matches the expected value (this is a placeholder assertion, replace with actual expected value)
    let computed_trap_commitment: Field = poseidon_hash_2([private_inputs.trap_value as Field, private_inputs.secret]);
    println(f"Computed Trap Commitment: {computed_trap_commitment}");
    assert(computed_trap_commitment == trap_commitment, "Invalid Trap Commitment");
}