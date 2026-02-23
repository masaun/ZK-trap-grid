/**
 * @notice - Struct to hold all public inputs for the position-movement circuit
 * @param move_x - The x-coordinate of the move
 * @param move_y - The y-coordinate of the move
 * @param is_hit - The claimed result of the move (1 for hit, 0 for miss)
 */
pub struct PublicInputs {
    pub move_x: u32,
    pub move_y: u32,
    pub is_hit: u32,
}