# ZK Trap Grid Game - Position Movement Circuit Integration

This directory contains the complete implementation of the ZK Trap Grid game using the **trap-grid-position-movement** circuit for on-chain proof verification on Stellar Testnet.

## 🎯 Overview

The Trap Grid game is a two-player zero-knowledge game where:
- **Player A (Defender)** sets up hidden traps on an 8x8 grid
- **Player B (Attacker)** makes moves to discover traps
- **Defender proves** hit/miss results using ZK proofs without revealing trap positions
- **Proofs are verified on-chain** on Stellar using the UltraHonk verifier

## 🏗️ Architecture

### Position Movement Circuit

The game uses the **trap-grid-position-movement** circuit located at:
```
../trap-grid/trap-grid-position-movement/
```

**Circuit Inputs:**
- **Public inputs:**
  - `trap_commitment` (Field): Poseidon hash of the trap value
  - `move_x` (u32): X coordinate of the move
  - `move_y` (u32): Y coordinate of the move
  - `is_hit` (u32): Claimed result (0 = miss, 1 = hit)

- **Private inputs:**
  - `trap_value` (u32): Actual trap value at the position (0 or 1)

**Circuit Constraints:**
1. Validates coordinates are within grid (0-7)
2. Ensures trap_value is boolean (0 or 1)
3. Verifies claimed result matches actual trap value
4. Computes trap commitment: `poseidon_hash_1([trap_value])`
5. Verifies computed commitment matches public commitment

### Smart Contracts

**1. UltraHonk Verifier Contract** (`../rs-soroban-ultrahonk/`)
- Verifies UltraHonk proofs on-chain
- Initialized with the verification key from the position-movement circuit
- Used by the game contract to validate defender's proofs

**2. Trap Grid Game Contract** (`./contracts/trap-grid/`)
- Manages game state (players, moves, hits/misses)
- Validates moves and calls the verifier contract
- No longer requires upfront trap commitment (simplified from merkle root approach)

**3. Mock Game Hub Contract** (`./contracts/mock-game-hub/`)
- Manages game sessions and scoring (optional)

### Frontend Application (`./app/`)

**Key Components:**
- **DefenderUI**: Set up traps and store them locally
- **AttackerUI**: Make moves and display results
- **ZK Proof Generation**: Generate proofs using `@noir-lang/noir_js` and `@aztec/bb.js`
- **Poseidon Hashing**: Compute trap commitments using `poseidon-lite`

## 🚀 Quick Start

### Prerequisites

1. **Stellar CLI** - Install from https://developers.stellar.org/docs/tools/developer-tools/cli/install
2. **Rust & Cargo** - For building Soroban contracts
3. **Node.js & npm** - For frontend and circuit compilation
4. **Noir (nargo)** - For compiling the circuit
5. **Freighter Wallet** - Browser extension for signing transactions

### Setup for Local Development

1. **Start a local Stellar network:**
   ```bash
   stellar network start standalone
   ```

2. **Build and deploy contracts:**
   ```bash
   chmod +x deploy-local.sh
   ./deploy-local.sh
   ```

   This script will:
   - Compile the position-movement circuit
   - Generate the verification key
   - Build the verifier contract with the VK
   - Deploy all contracts to the local network
   - Save contract addresses to `app/.env.local`

3. **Copy circuit artifact:**
   ```bash
   mkdir -p app/public/circuits
   cp ../circuits/position-movement/target/position_movement.json app/public/circuits/trap_grid_position_movement.json
   ```

4. **Install frontend dependencies and start:**
   ```bash
   cd app
   npm install
   npm run dev
   ```

5. **Open the app:**
   ```
   http://localhost:5678
   ```

### Deploy to Stellar Testnet

1. **Create and fund a testnet account:**
   ```bash
   stellar keys generate my-testnet-key
   stellar keys fund my-testnet-key --network testnet
   ```

2. **Set environment variable:**
   ```bash
   export STELLAR_SOURCE_ACCOUNT=my-testnet-key
   # Or add to .env file:
   echo "STELLAR_SOURCE_ACCOUNT=my-testnet-key" > .env
   ```

3. **Deploy to testnet:**
   ```bash
   chmod +x deploy-testnet.sh
   ./deploy-testnet.sh
   ```

4. **Update frontend configuration:**
   The script automatically saves testnet contract addresses to `app/.env.local`

## 🎮 How to Play

### As Defender (Player A)

1. **Connect your Freighter wallet** on the Defender page
2. **Set trap positions** by clicking cells on the grid
3. **Save trap grid** - traps are stored locally in browser storage
4. **Enter attacker's address** and points
5. **Start the game** - creates the game on-chain
6. **Wait for attacker moves**, then generate proofs for each move

### As Attacker (Player B)

1. **Connect your Freighter wallet** on the Attacker page
2. **Enter the session ID** from the defender
3. **Load the game** to see the grid
4. **Click cells to make moves** - you can select your target
5. **Submit move** - defender will need to provide a proof
6. **View results** - hits (💥) and misses (❌) are revealed

## 🔐 ZK Proof Generation Flow

### Defender's Proof Generation

When an attacker makes a move at position (x, y):

1. **Retrieve trap value** from local storage:
   ```typescript
   const trapValue = trapValues[x * 8 + y]; // 0 or 1
   ```

2. **Compute trap commitment**:
   ```typescript
   import { computeTrapCommitment } from '@/lib/zkProof';
   const commitment = computeTrapCommitment(trapValue);
   // commitment = poseidon_hash_1([trapValue])
   ```

3. **Generate ZK proof**:
   ```typescript
   import { generateProof } from '@/lib/zkProof';
   const proofData = await generateProof(
     trapValue,     // Private: actual trap value
     moveX,         // Public
     moveY,         // Public
     isHit          // Public: trapValue === 1
   );
   ```

4. **Submit proof on-chain**:
   ```typescript
   await makeMove(
     sessionId,
     moveX,
     moveY,
     isHit,
     proofData.proof,
     proofData.publicInputs,
     publicKey
   );
   ```

5. **Contract verifies proof**:
   - Calls the UltraHonk verifier contract
   - Verifier checks the proof against the VK
   - If valid, move is recorded on-chain

## 📁 Directory Structure

```
.
├── app/                          # Next.js frontend
│   ├── src/
│   │   ├── app/                 # Next.js app pages
│   │   │   ├── defender/        # Defender UI
│   │   │   └── attacker/        # Attacker UI
│   │   ├── components/          # React components
│   │   ├── lib/
│   │   │   ├── zkProof.ts       # ZK proof generation
│   │   │   ├── poseidon.ts      # Poseidon hashing
│   │   │   ├── stellar.ts       # Stellar SDK integration
│   │   │   └── utils.ts         # Utility functions
│   │   └── types/               # TypeScript types
│   ├── public/circuits/         # Compiled circuit artifacts
│   └── package.json
├── contracts/
│   ├── trap-grid/               # Game contract
│   │   └── src/lib.rs
│   └── mock-game-hub/           # Hub contract
├── deploy-local.sh              # Local deployment script
├── deploy-testnet.sh            # Testnet deployment script
└── README.md                    # This file
```

## 🔧 Technical Details

### Circuit Compilation

The position-movement circuit is compiled using:
```bash
cd ../trap-grid/trap-grid-position-movement
nargo compile
```

This generates:
- `target/position_movement.json` - Circuit artifact
- Used for proof generation in the frontend

### Verification Key Generation

The VK is generated using BB.js:
```bash
node ./node_modules/@aztec/bb.js/dest/node/main.js write_vk_ultra_keccak_honk \
  -b ./target/position_movement.json \
  -o ./target/vk
```

This VK is embedded in the verifier contract at deployment.

### Proof System

- **Backend**: UltraHonk with Keccak transcript
- **Proof size**: ~2144 bytes
- **Public inputs**: 4 fields (128 bytes)
- **Verifier gas**: Within Stellar's protocol limits ✅

### Smart Contract Integration

The game contract verifies proofs by calling:
```rust
let verifier = VerifierClient::new(&env, &verifier_addr);
let proof_valid = verifier.verify(&proof, &public_inputs);
```

The verifier contract uses the ultrahonk-soroban-verifier library:
```rust
let verifier = UltraHonkVerifier::new(&env, &vk_bytes)?;
verifier.verify(&proof_bytes, &public_inputs)?;
```

## 🧪 Testing

### Local Testing

Run the circuit test:
```bash
cd ../trap-grid/trap-grid-position-movement
sh circuit_test.sh
```

### On-chain Verification Test

The test verification script demonstrates end-to-end proof generation and on-chain verification:
```bash
cd ../
sh test-verification_trap-grid_trap-grid-position-movement-circuit.sh
```

This script:
1. Compiles the circuit
2. Generates a test proof
3. Deploys the verifier to testnet
4. Verifies the proof on-chain ✅

## 📚 References

### Related Files
- Circuit: `../trap-grid/trap-grid-position-movement/`
- Verifier: `../rs-soroban-ultrahonk/`
- Test script: `../test-verification_trap-grid_trap-grid-position-movement-circuit.sh`

### Documentation
- [Noir Documentation](https://noir-lang.org/)
- [Stellar Smart Contracts](https://developers.stellar.org/docs/smart-contracts)
- [UltraHonk Proving System](https://github.com/AztecProtocol/aztec-packages/tree/master/barretenberg)

## 🎯 Key Improvements from Merkle Approach

1. **Simplified Circuit**: No complex Merkle tree verification
2. **Smaller Proofs**: Commitment-based approach is more efficient
3. **On-chain Verification**: Successfully verifies within Stellar's limits
4. **Better UX**: Defender doesn't need to pre-commit trap grid
5. **Lower Gas Costs**: Simpler verification logic

## 🐛 Troubleshooting

### Circuit Build Issues
```bash
# Reinstall dependencies
cd ../trap-grid/trap-grid-position-movement
rm -rf node_modules package-lock.json
npm install
```

### Frontend Dependencies
```bash
cd app
npm install poseidon-lite @noir-lang/noir_js @noir-lang/backend_barretenberg
```

### Contract Deployment
```bash
# Ensure stellar CLI is up to date
stellar version
# Should be >= 21.5.0
```

## 🚀 Next Steps

1. **Implement interactive proof generation UI** in DefenderUI
2. **Add proof verification status** before on-chain submission
3. **Optimize proof generation** with caching and batching
4. **Add game statistics** and leaderboard
5. **Deploy to mainnet** after thorough testing

## 📝 License

This project is part of the ZK Gaming on Stellar hackathon submission.

---

Built with ❤️ using Noir, Stellar, and UltraHonk
