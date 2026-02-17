use binary_merkle_root::binary_merkle_root;

use crate::{
    libs::hash::poseidon::poseidon_hash::{
        poseidon_hash_1, 
        poseidon_hash_2, 
        poseidon_hash_3, 
        poseidon_hash_4,
        poseidon_hash_5,
        poseidon_hash_6
    },
    types::{
        constants::{ MERKLE_TREE_DEPTH },
    }
};
//use std::hash::poseidon;

// @dev - The length of the Merkle proof for the commitment merkle proof
// @dev - [Key Point]: The MERKLE_PROOF_LENGTH would always be equal to the MERKLE_TREE_DEPTH for a binary Merkle tree, since each level of the tree contributes one sibling node to the proof. Therefore, we can set MERKLE_PROOF_LENGTH to be equal to MERKLE_TREE_DEPTH.
pub global MERKLE_PROOF_LENGTH: u32 = MERKLE_TREE_DEPTH;

// @dev - The depth of the Merkle Tree for the commitments
//pub global MERKLE_TREE_DEPTH: u32 = 16;

/**
    * @notice - Computes the Binary Merkle Root for a given leaf and a Merkle proof
    * @param commitment - The leaf value (trap value in our case)
    * @returns The computed Merkle root
    */
pub fn compute_merkle_root(
    commitment: Field, // @dev - Leaf
    merkle_proof_length: u32,
    merkle_proof_indices: [u1; MERKLE_TREE_DEPTH],
    merkle_proof_siblings: [Field; MERKLE_TREE_DEPTH],
) -> Field {
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
