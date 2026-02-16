use crate::types::constants::{ GRID_SIZE, NUM_CELLS, TREE_DEPTH };

pub struct PublicInputs {
    pub trap_root: Field,
    pub move_x: u32,
    pub move_y: u32,
    pub is_hit: u32,
    pub merkle_path: [Field; TREE_DEPTH],
    pub merkle_indices: [Field; TREE_DEPTH]
}