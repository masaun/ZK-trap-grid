use crate::{
    main,
    types::{
        public_inputs::PublicInputs,
    },
    PrivateInputs
};

#[test]
fn test_main() {
    // ------------ PUBLIC INPUTS ------------- //
    let public_inputs = PublicInputs {
        move_x: 1,
        move_y: 2,
        is_hit: 1
    };

    // ------------ PRIVATE INPUTS ------------- //
    let private_inputs = PrivateInputs {
        trap_value: 1 // @dev - 1 for trap (hit), 0 for no trap (miss)
    };

    // @dev - Execute the main function with the test inputs
    main(public_inputs, private_inputs);

    // @dev - Test passes if no assertion fails
}