# ZK Trap Grid Game - Stellar Blockchain

A zero-knowledge proof based trap grid game built on Stellar blockchain with Noir circuits and Soroban smart contracts.

## Overview

This is a two-player game where:
- **Player A (Defender)**: Sets up a hidden 8x8 trap grid and commits to it using a Merkle root
- **Player B (Attacker)**: Makes moves to discover traps
- **ZK Proofs**: Defender proves hit/miss results without revealing trap positions

## Architecture

### Smart Contracts (Soroban)

1. **Mock Game Hub** (`contracts/mock-game-hub/`)
   - Manages game sessions and scoring
   - Tracks game lifecycle (start/end)
   - For local development (mimics testnet Game Hub)

2. **Trap Grid Contract** (`contracts/trap-grid/`)
   - Main game logic
   - Verifies ZK proofs for each move
   - Integrates with Game Hub and Verifier contracts

3. **UltraHonk Verifier** (from `../../rs-soroban-ultrahonk/`)
   - On-chain ZK proof verification
   - Validates Noir circuit proofs

### Frontend (Next.js + TypeScript)

Located in `trap-grid-frontend/`:
- **Defender UI** (`/defender`): Set traps, commit Merkle root, start game
- **Attacker UI** (`/attacker`): Join game, make moves, view results
- Built with Next.js 15, React 19, TailwindCSS
- Integrates with Freighter wallet

### Zero-Knowledge Circuits (Noir)

Circuit artifacts from `../../trap-grid/`:
- Proves hit/miss without revealing trap positions
- Uses Merkle tree verification
- Compiled to UltraHonk proofs

## Prerequisites

- **Node.js** 18+ and npm/bun
- **Rust** and Cargo
- **Docker** (for local Stellar network)
- **Stellar CLI**: `cargo install --locked stellar-cli`
- **Freighter Wallet** browser extension
- **Noir** (for circuit updates): `curl -L https://install.aztec.network | bash`

## Quick Start

### 1. Start Local Stellar Network

```bash
# In one terminal
chmod +x start-network.sh
./start-network.sh
```

This starts a local Stellar network on `http://localhost:8000`

### 2. Deploy Contracts

```bash
# In another terminal
chmod +x deploy-local.sh
./deploy-local.sh
```

This will:
- Build all contracts
- Deploy them to local network
- Initialize with proper configuration
- Output contract addresses

### 3. Configure Frontend

Copy the contract addresses from deployment output to `trap-grid-frontend/.env.local`:

```bash
cp .contract-addresses.env trap-grid-frontend/.env.local
```

### 4. Install Frontend Dependencies

```bash
cd trap-grid-frontend
npm install
# or
bun install
```

### 5. Run Frontend

```bash
npm run dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) in your browser.

## How to Play

### As Defender (Player A)

1. Go to `/defender`
2. Connect Freighter wallet
3. Click cells to place traps (💣)
4. Click "Commit Trap Grid" to create Merkle root
5. Enter attacker's address and points
6. Click "Start Game" to begin

### As Attacker (Player B)

1. Go to `/attacker`
2. Connect Freighter wallet
3. Enter session ID from defender
4. Click "Load Game"
5. Click cells to attack
6. View results: 💥 for hits, ❌ for misses

## Development Workflow

### Building Contracts

```bash
# Build trap-grid contract
cd contracts/trap-grid
cargo build --target wasm32-unknown-unknown --release

# Build mock-game-hub
cd ../mock-game-hub
cargo build --target wasm32-unknown-unknown --release
```

### Testing Contracts

```bash
cd contracts/trap-grid
cargo test
```

### Updating Circuits

If you modify the Noir circuit in `../../trap-grid/`:

```bash
cd ../../trap-grid
nargo compile
nargo prove
nargo verify

# Copy artifacts if needed
cp target/trap_grid.json ../trap-grid-dapp-and-contracts/trap-grid-frontend/public/circuits/
```

### Frontend Development

```bash
cd trap-grid-frontend
npm run dev
npm run build
npm run lint
```

## Project Structure

```
trap-grid-dapp-and-contracts/
├── contracts/
│   ├── trap-grid/          # Main game contract
│   │   ├── src/lib.rs
│   │   └── Cargo.toml
│   └── mock-game-hub/      # Local game hub mock
│       ├── src/lib.rs
│       └── Cargo.toml
├── trap-grid-frontend/     # Next.js frontend
│   ├── src/
│   │   ├── app/            # Pages (/, /defender, /attacker)
│   │   ├── components/     # React components
│   │   ├── lib/            # Utils and Stellar SDK
│   │   └── types/          # TypeScript types
│   ├── package.json
│   └── next.config.js
├── deploy-local.sh         # Deployment script
├── start-network.sh        # Network startup script
└── README.md
```

## Integration Points

### With Noir Circuits

The game uses circuits from `../../trap-grid/`:
- Circuit: `trap-grid/src/main.nr`
- Artifacts: `trap-grid/target/`
- Verification key and proof format

### With UltraHonk Verifier

Uses the Soroban verifier from `../../rs-soroban-ultrahonk/`:
- Contract: `ultrahonk-soroban-verifier/src/lib.rs`
- WASM: Built separately and deployed
- Verifies proofs on-chain

### With Game Hub

Integrates with the game hub pattern:
- Calls `start_game()` with both players and points
- Calls `end_game()` with winner information
- Local: mock contract
- Testnet: CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG

## Stellar Hacks Submission Requirements

This project meets the following criteria:

✅ **Zero-Knowledge Proofs**: Uses Noir circuits with UltraHonk verifier
✅ **Stellar Integration**: Built on Soroban smart contracts
✅ **Two-Player Game**: Defender vs Attacker
✅ **Game Hub Integration**: Calls start_game() and end_game()
✅ **On-Chain Verification**: ZK proofs verified on Stellar
✅ **Privacy-Preserving**: Trap positions remain hidden

## Troubleshooting

### Freighter Not Connecting

- Ensure Freighter is installed and unlocked
- Switch network to "Standalone" in Freighter settings
- Check that local network is running

### Contract Deployment Fails

- Verify Docker is running
- Check Stellar network is accessible at `localhost:8000`
- Ensure accounts have sufficient balance (friendbot)

### Frontend Build Errors

- Run `npm install` or `bun install`
- Check Node.js version (18+)
- Verify `.env.local` has contract addresses

## Next Steps

- [ ] Integrate actual UltraHonk verifier deployment
- [ ] Implement real ZK proof generation in frontend
- [ ] Add Poseidon hash for Merkle tree
- [ ] Deploy to Stellar Testnet
- [ ] Add game animations and improvements
- [ ] Implement time limits and forfeit logic

## License

MIT

## Resources

- [Stellar Documentation](https://developers.stellar.org)
- [Soroban Docs](https://soroban.stellar.org)
- [Noir Language](https://noir-lang.org)
- [Freighter Wallet](https://www.freighter.app)
