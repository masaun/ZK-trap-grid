# Trap Grid Game - Deployment Guide

## Overview

This guide covers deploying the Trap Grid ZK game to **Stellar Testnet** for the Stellar Hacks ZK Gaming hackathon submission.

## Game Hub Integration

**Important:** This game integrates with the official hackathon Game Hub contract deployed on Stellar Testnet:

```
Game Hub Contract: CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG
```

The trap-grid contract calls:
- `start_game()` - When a new game session is created
- `end_game()` - When a game session completes with a winner

This meets the [hackathon submission requirements](https://dorahacks.io/hackathon/stellar-hacks-zk-gaming/detail#submission-requirements).

---

## Prerequisites

### 1. Install Dependencies

```bash
# Stellar CLI
cargo install stellar-cli

# Noir compiler
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
noirup

# Node.js (for circuit compilation)
# Install from https://nodejs.org/
```

### 2. Create Testnet Account

```bash
# Generate new keypair
stellar keys generate trap-grid-deployer --network testnet

# Fund account from friendbot
stellar keys fund trap-grid-deployer --network testnet

# Verify balance
stellar keys address trap-grid-deployer
```

---

## Deployment to Stellar Testnet

### Step 1: Set Environment

```bash
cd contracts

# Set your testnet account
export STELLAR_SOURCE_ACCOUNT=trap-grid-deployer
```

### Step 2: Run Deployment Script

```bash
chmod +x deploy-testnet.sh
./deploy-testnet.sh
```

This script will:
1. Build the **trap-grid-position-movement** circuit
2. Generate verification key (VK)
3. Build the **UltraHonk verifier** contract with embedded VK
4. Build the **trap-grid** game contract
5. Deploy verifier to Stellar Testnet
6. Deploy trap-grid contract to Stellar Testnet
7. Initialize trap-grid with:
   - Admin: Your testnet account
   - **Game Hub: CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG** (official)
   - Verifier: Your deployed verifier contract

### Step 3: Verify Deployment

After successful deployment, you'll see:

```
════════════════════════════════════════════════════════════
✅ Deployment to Stellar Testnet Complete!
════════════════════════════════════════════════════════════

Contract Addresses:
-------------------
Game Hub:   CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG
Trap Grid:  <YOUR_DEPLOYED_ADDRESS>
Verifier:   <YOUR_DEPLOYED_ADDRESS>

🔗 View on Stellar Expert:
   Game Hub:   https://stellar.expert/explorer/testnet/contract/CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG
   Trap Grid:  https://stellar.expert/explorer/testnet/contract/<YOUR_ADDRESS>
   Verifier:   https://stellar.expert/explorer/testnet/contract/<YOUR_ADDRESS>
```

The contract addresses are automatically saved to `app/.env.local`.

---

## Local Development

For **local testing**, use the local deployment script which deploys a mock game hub:

```bash
# Start local Stellar network (in a separate terminal)
stellar network start

# Deploy to local network
./deploy-local.sh
```

**Note:** Local deployment uses a mock game hub for development convenience. The testnet deployment uses the real hackathon game hub.

---

## Frontend Setup

### Step 1: Copy Circuit Artifact

```bash
# Copy compiled circuit to frontend
cp ../circuits/position-movement/target/position_movement.json \
   app/public/circuits/trap_grid_position_movement.json
```

### Step 2: Install Dependencies

```bash
cd app
npm install
```

### Step 3: Run Development Server

```bash
npm run dev
```

The app will start at http://localhost:5678

---

## Testing On-Chain Verification

### Defender (Player A) Flow:
1. Connect wallet (Freighter, Albedo, xBull)
2. Set traps on the 8x8 grid
3. Enter attacker's address
4. Click "Start Game"
   - Calls `trap-grid.start_game()`
   - Which calls `game-hub.start_game()` (official contract)
5. Wait for attacker's moves
6. Generate ZK proof for each move
7. Submit proof for verification
   - Calls `trap-grid.make_move()` with proof
   - Verifier contract validates proof on-chain
8. Game ends when all moves are made
   - Calls `game-hub.end_game()` (official contract)

### Attacker (Player B) Flow:
1. Connect wallet
2. Enter defender's session ID
3. Load game state
4. Click cells to make moves
5. Wait for defender's proof
6. View results (hit/miss)

---

## Circuit Details

**Circuit:** `trap-grid-position-movement`

**Inputs:**
- `trap_value` (private) - The trap at a position (0 or 1)
- `position_x` (public) - X coordinate of position
- `position_y` (public) - Y coordinate of position  
- `is_hit` (public) - Whether position has a trap

**Verification:**
- Computes: `commitment = poseidon_hash_1([trap_value])`
- Asserts: `is_hit == (trap_value == 1)`
- Proves the trap state matches claimed hit/miss without revealing all trap positions

**Proof System:** UltraHonk with Keccak transcript  
**Proof Size:** ~2144 bytes (within Stellar limits)

---

## Troubleshooting

### "Account not funded"
```bash
stellar keys fund trap-grid-deployer --network testnet
```

### "Verifier WASM not found"
```bash
cd ../rs-soroban-ultrahonk
stellar contract build
cd -
```

### "Circuit not compiled"
```bash
cd ../trap-grid/trap-grid-position-movement
nargo compile
npm install
npm run build:vk
cd -
```

### Check contract on Stellar Expert
Visit: https://stellar.expert/explorer/testnet/contract/<YOUR_CONTRACT_ADDRESS>

---

## Submission Checklist

For Stellar Hacks ZK Gaming hackathon:

- ✅ Contracts deployed on Stellar Testnet
- ✅ Game calls `start_game()` on official game hub: `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG`
- ✅ Game calls `end_game()` on official game hub
- ✅ On-chain ZK proof verification using UltraHonk verifier
- ✅ Frontend dApp for playing the game
- ✅ Working wallet integration (Freighter, Albedo, xBull)

---

## Contract Addresses

### Official Hackathon Contracts
- **Game Hub (Testnet):** `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG`

### Your Deployed Contracts
After running `./deploy-testnet.sh`, save these addresses:
- **Trap Grid:** (see deployment output)
- **Verifier:** (see deployment output)

---

## Resources

- [Hackathon Page](https://dorahacks.io/hackathon/stellar-hacks-zk-gaming)
- [Stellar Docs](https://developers.stellar.org)
- [Noir Documentation](https://noir-lang.org)
- [UltraHonk on Stellar](https://github.com/TechySauce/rs-soroban-ultrahonk)

---

## Support

For issues or questions:
1. Check the [STATUS.md](docs/STATUS.md) file
2. Review [IMPLEMENTATION_SUMMARY.md](docs/IMPLEMENTATION_SUMMARY.md)
3. See [TRAP_GRID_README.md](docs/TRAP_GRID_README.md) for game mechanics
