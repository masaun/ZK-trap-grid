echo "Show the size of the ZK circuit..."
bb gates -b target/position_movement.json | grep "circuit"

# Scheme is: ultra_honk, num threads: 8
#         "circuit_size": 3567

# @aztec/bb.js
#   - Performance and limitations: 
#     - Max circuit size is 2^19 gates (524,288). This is due to the underlying WASM 4GB memory limit.
# 
# Link: https://www.npmjs.com/package/@aztec/bb.js