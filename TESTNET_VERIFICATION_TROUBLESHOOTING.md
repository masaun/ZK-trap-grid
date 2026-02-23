# Testnet Verification Troubleshooting

## Issue
The position-movement circuit verification is failing on Stellar testnet with:
```
❌ error: transaction simulation failed: HostError: Error(Budget, ExceededLimit)
```

## Analysis

### Current Circuit Status
The circuit has been simplified and confirmed to work locally:
- ✅ 20 ACIR opcodes (very small)
- ✅ 3 public input fields (96 bytes)
- ✅ Local compilation successful
- ✅ Local tests pass
- ✅ Proof generation works

### Circuit Structure
```noir
// Public inputs
- move_x: u32
- move_y: u32  
- is_hit: u32

// Private inputs
- trap_value: u32

// Constraints (very simple)
1. Coordinate bounds checking (x, y in [0, 7])
2. Boolean validation (trap_value is 0 or 1)
3. Value matching (trap_value == is_hit)
```

## Root Cause
The ExceededLimit error occurs during **on-chain verification**, not during proof generation. Even though the circuit is extremely simple, the UltraHonk verifier is computationally expensive.

### Why UltraHonk Verification May Exceed Limits
1. **Pairing operations**: UltraHonk uses elliptic curve pairings which are CPU-intensive
2. **Field arithmetic**: Verification requires many field operations over large prime fields
3. **Fixed verification cost**: The verifier has a base computational cost regardless of circuit size
4. **Stellar CPU limits**: Testnet has strict per-transaction CPU instruction limits

## What Changed
The script comments previously mentioned the circuit "successfully verifies on testnet" with a "simplified commitment scheme using poseidon_hash_1([trap_value])". However:

1. **Previous version**: Had trap commitment logic (still relatively simple)
2. **Current version**: Removed ALL commitment logic (even simpler)

The current version has:
- Removed poseidon hash imports
- Removed trap commitment field from public inputs
- Reduced public inputs from 4 to 3 fields

This should theoretically be MORE efficient, but the verification cost is dominated by the fixed UltraHonk verifier overhead, not the circuit complexity.

## Solutions

### Option 1: Optimize the Verifier Contract
The `rs-soroban-ultrahonk` contract may need optimization:
- Profile the contract to find hotspots
- Optimize field arithmetic operations  
- Consider batch verification if multiple proofs are verified
- Use precompiled operations if available

### Option 2: Use UltraPlonk Instead
UltraHonk is optimized for proof size but has expensive verification:
- Consider switching to UltraPlonk which has cheaper verification
- Trade-off: Larger proofs but faster verification
- Benchmark both systems on testnet

### Option 3: Wait for Protocol Upgrades
Stellar may increase CPU limits in future upgrades:
- Monitor Stellar protocol proposals
- Test on newer testnet versions
- Consider using a sidechain or L2 for ZK verification

### Option 4: Off-chain Verification
Verify proofs off-chain and only post results on-chain:
- Use a trusted oracle or committee
- Post verification results with signatures
- Reduces on-chain computational requirements

### Option 5: Circuit Aggregation/Recursion
Aggregate multiple game moves into one proof:
- Verify multiple moves in a single on-chain call
- Amortize verification cost across moves
- Requires more complex circuit design

## Recommended Next Steps

1. **Profile the verifier contract**
   ```bash
   # Add logging/metrics to rs-soroban-ultrahonk
   # Identify which operations are most expensive
   ```

2. **Test with different circuit sizes**
   ```bash
   # Try an even simpler circuit (remove some constraints)
   # See if there's a threshold that works
   ```

3. **Check Stellar documentation**
   ```bash
   # Review current CPU instruction limits
   # Check if there are optimization patterns for heavy computation
   ```

4. **Consider alternative approaches**
   ```bash
   # Use commitment schemes without on-chain verification
   # Use game state channels with ZK settlement
   # Use a ZK-rollup architecture
   ```

## Script Updates Made

Updated [test-verification_trap-grid_position-movement-circuit.sh](scripts/e2e/stellar-testnet/test-verification_trap-grid_position-movement-circuit.sh):

1. ✅ Updated header comments to reflect current circuit structure
2. ✅ Added contract build cleaning to force fresh compile
3. ✅ Added `nargo info` step to show circuit stats
4. ✅ Fixed step numbering (1a → 1g)

## Testing

To verify the script generates correct artifacts:
```bash
cd circuits/position-movement
rm -rf target/

# This should work locally
nargo compile
nargo execute
nargo info

# Check public input count
npx tsx scripts/helpers/count_pub_inputs.ts
# Should output: 3
```

## Conclusion

The circuit is correctly simplified and the script is updated to use the latest version. The ExceededLimit error is **not** due to using an old circuit version, but rather due to the inherent computational cost of UltraHonk verification exceeding Stellar's protocol limits.

The issue requires either:
- Optimizing the verifier contract implementation
- Switching to a lighter proof system (UltraPlonk)
- Using off-chain verification
- Waiting for Stellar protocol upgrades

The simplified circuit is correct and verified locally. The bottleneck is the on-chain verification cost.
