use binary_merkle_root::binary_merkle_root;

use crate::libs::hash::poseidon::poseidon_hash::{
    poseidon_hash_1, 
    poseidon_hash_2, 
    poseidon_hash_3, 
    poseidon_hash_4,
    poseidon_hash_5,
    poseidon_hash_6
};
//use std::hash::poseidon;

// @dev - The length of the Merkle proof for the commitment merkle proof
pub global MERKLE_PROOF_LENGTH: u32 = 4;

// @dev - The depth of the Merkle Tree for the commitments
pub global MERKLE_TREE_DEPTH: u32 = 16;

/**
    * @notice - Computes the Binary Merkle Root for a given leaf and a Merkle proof
    * @param commitment - The leaf value (trap value in our case)
    * @returns The computed Merkle root
    */
pub fn compute_merkle_root(
    commitment: Field, // @dev - Leaf
) -> Field {
    let merkle_proof_length: u32 = MERKLE_PROOF_LENGTH;,
    let merkle_proof_indices: [u1; MERKLE_TREE_DEPTH] = [0; MERKLE_TREE_DEPTH],
    let merkle_proof_siblings: [Field; MERKLE_TREE_DEPTH] = [0; MERKLE_TREE_DEPTH];

    let merkle_root = binary_merkle_root(
        poseidon_hash_2, // @dev - This should be replaced depends on the number of elements of the Merkle proof (e.g., if the tree is binary, use poseidon_hash_2; if ternary, use poseidon_hash_3, etc.)
        commitment,
        merkle_proof_length,
        merkle_proof_indices,
        merkle_proof_siblings
    );
    merkle_root
}



// /// Verifies a Merkle proof for a leaf
// /// depth = 6 for 64 leaves
// pub fn verify_merkle_proof(
//     leaf: Field,
//     path: [Field; 6],
//     path_indices: [Field; 6]
// ) -> Field {

//     let mut hash = leaf;

//     for i in 0..6 {
//         let is_right = path_indices[i];

//         // Ensure index bit is boolean
//         assert(is_right == 0 || is_right == 1);

//         if is_right == 0 {
//             hash = poseidon_hash_2(hash, path[i]);
//         } else {
//             hash = poseidon_hash_2(path[i], hash);
//         }
//     }

//     hash
// }
