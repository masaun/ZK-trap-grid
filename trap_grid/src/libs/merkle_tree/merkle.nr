use crate::libs::hash::poseidon::poseidon_hash::{
    poseidon_hash_1, 
    poseidon_hash_2, 
    poseidon_hash_3, 
    poseidon_hash_4,
    poseidon_hash_5,
    poseidon_hash_6
};
//use std::hash::poseidon;

/// Verifies a Merkle proof for a leaf
/// depth = 6 for 64 leaves
pub fn verify_merkle_proof(
    leaf: Field,
    path: [Field; 6],
    path_indices: [Field; 6]
) -> Field {

    let mut hash = leaf;

    for i in 0..6 {
        let is_right = path_indices[i];

        // Ensure index bit is boolean
        assert(is_right == 0 || is_right == 1);

        if is_right == 0 {
            hash = poseidon_hash_2(hash, path[i]);
        } else {
            hash = poseidon_hash_2(path[i], hash);
        }
    }

    hash
}
