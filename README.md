# ZK Trap Grid 🎲

This project is the `Zero-Knowledge` based two-player game built on `Noir` (zkDSL powered by Aztec) and Stellar blockchain

## Overview

**ZK Trap Grid** is a strategic hide-and-seek game where cryptographic proofs enable fair gameplay without revealing secrets:

- 🛡️ **Defender (Player A)** secretly places traps on an 8×8 grid
- ⚔️ **Attacker (Player B)** makes moves to discover trap locations
- 🔐 **Defender** proves each hit/miss result using zero-knowledge proofs without revealing the entire trap layout
- ⛓️ **On-chain verification** ensures all proofs are validated on Stellar using UltraHonk

The game demonstrates practical ZK applications in gaming: maintaining hidden state while proving game outcomes honestly. All game logic, state, and proof verification happen on-chain.

---

## Tech Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **ZK Circuit Language** | [Noir](https://noir-lang.org/) | Write zero-knowledge circuits |
| **ZK Proof System** | [UltraHonk](https://github.com/AztecProtocol/aztec-packages/tree/master/barretenberg/cpp/src/barretenberg/honk) | Generate and verify succinct proofs |
| **ZK Library** | [@aztec/bb.js](https://www.npmjs.com/package/@aztec/bb.js) v0.87.0 | Generate proofs in browser/Node.js |
| **Blockchain** | [Stellar](https://stellar.org/) (Testnet) | On-chain state and verification |
| **Smart Contracts** | Rust + Soroban SDK | Game logic and verifier contracts |
| **Frontend** | Next.js 15 + TypeScript | User interface and proof generation |
| **Wallet** | Freighter + stellar-wallet-kit | User authentication and signing |
| **Styling** | TailwindCSS | UI components |
| **Cryptographic Hash** | Poseidon | Merkle tree commitments |

---

## What ZK Circuits Prove

This project implements **3 Noir circuits** that progressively demonstrate different ZK techniques:

| Circuit | File | What It Proves | Key Techniques |
|---------|------|----------------|----------------|
| **Position Movement** | [circuits/position-movement/src/main.nr](circuits/position-movement/src/main.nr) | Proves a move at (x,y) is a hit/miss based on the trap value at that position | ✓ Coordinate validation<br>✓ Boolean constraint<br>✓ Direct value matching |
| **Trap Commitment** | [circuits/trap-commitment/src/main.nr](circuits/trap-commitment/src/main.nr) | Proves a committed trap value matches the secret value using Poseidon hashing | ✓ Commitment scheme<br>✓ Poseidon hash<br>✓ Preimage resistance |
| **Trap Merkle Root** | [circuits/trap-merkle-root/src/main.nr](circuits/trap-merkle-root/src/main.nr) | Proves a single trap position is part of the entire grid without revealing other traps | ✓ Merkle tree verification<br>✓ Binary tree proof<br>✓ Selective disclosure |

**Circuit Evolution:**
1. **Position Movement** (Basic) - Simple position verification
2. **Trap Commitment** (Intermediate) - Adds cryptographic commitments  
3. **Trap Merkle Root** (Advanced) - Full privacy with Merkle trees


---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend (Next.js)                       │
│  ┌──────────────┐              ┌──────────────┐                │
│  │ Defender UI  │              │ Attacker UI  │                │
│  │ /defender    │              │ /attacker    │                │
│  └──────────────┘              └──────────────┘                │
│         │                              │                         │
│         │  1. Set traps                │  3. Make moves          │
│         │  2. Generate proofs          │  4. View results        │
│         └──────────────┬───────────────┘                         │
│                        │                                         │
│              ┌─────────▼─────────┐                              │
│              │  Wallet (Freighter) │                             │
│              └─────────┬─────────┘                              │
└────────────────────────┼─────────────────────────────────────────┘
                         │
                         │ Sign & Submit Transactions
                         │
┌────────────────────────▼─────────────────────────────────────────┐
│                    Stellar Blockchain                            │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Trap Grid Game Contract                        │ │
│  │  • Game state (traps, moves, scores)                       │ │
│  │  • Game logic (start, make_move, end)                      │ │
│  │  • Player management                                        │ │
│  └──────────────┬──────────────────────┬──────────────────────┘ │
│                 │                      │                         │
│                 │ verify()             │ start_game()            │
│                 │                      │ end_game()              │
│                 │                      │                         │
│  ┌──────────────▼──────────┐   ┌──────▼──────────────────────┐ │
│  │  Verifier Contract      │   │  Game Hub Contract          │ │
│  │  (UltraHonk)            │   │  (Official)                 │ │
│  │  • Validate ZK proofs   │   │  • Session management       │ │
│  │  • Position Movement VK │   │  • Scoring                  │ │
│  └─────────────────────────┘   └─────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

**Contract Flow:**
1. **Defender** calls `start_game()` → Trap Grid Contract → Game Hub (registers session)
2. **Attacker** calls `make_move(x, y)` → Trap Grid Contract stores move
3. **Defender** generates ZK proof off-chain → submits to `make_move()` with proof
4. **Trap Grid Contract** calls `verify()` → Verifier Contract validates proof
5. If proof valid, move is recorded; game continues
6. After all moves, `end_game()` → Game Hub (finalizes scores)

---

## User Flow

### **Phase 1: Game Setup (Defender)**

```
1. Defender connects wallet (Freighter)
2. Defender accesses /defender page
3. Defender clicks cells to place traps on 8×8 grid
4. Defender clicks "Start Game"
   └─> Frontend hashes trap grid with Poseidon
   └─> Calls trap_grid.start_game(merkle_root)
   └─> Game Hub registers game session
   └─> Game state stored on-chain
```

### **Phase 2: Moves & Proofs (Attacker & Defender)**

```
5. Attacker connects wallet
6. Attacker accesses /attacker page
7. Attacker selects a grid position (x, y) and submits move
   └─> Calls trap_grid.make_move(session_id, x, y)
   └─> Move stored on-chain, awaiting proof

8. Defender sees pending move
9. Defender generates ZK proof:
   └─> Input: trap_value (0 or 1), move coordinates
   └─> Circuit validates: trap_value == is_hit
   └─> Proof generated with bb.js
   └─> Defender submits proof to trap_grid.verify_move()

10. On-chain verification:
    └─> Verifier contract validates proof
    └─> If valid: update game state (hit/miss recorded)
    └─> If invalid: move rejected
    └─> Attacker sees result (without seeing other traps)

11. Repeat steps 7-10 for more moves
```

### **Phase 3: Game End**

```
12. After N moves or all traps found:
    └─> Either player calls trap_grid.end_game()
    └─> Game Hub finalizes scores
    └─> Winner determined
    └─> Game history viewable on blockchain
```

---

## Deployed Contract Addresses on Stellar Testnet

### **Official Contracts**

| Contract | Address | Description |
|----------|---------|-------------|
| **Game Hub** | `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG` | Official  game hub contract |

### **ZK Trap Grid Contracts**

| Contract | Address | Explorer Link |
|----------|---------|---------------|
| **Trap Grid Game** | `<YOUR_TRAP_GRID_CONTRACT>` | [View on Stellar Expert →](https://stellar.expert/explorer/testnet/contract/) |
| **UltraHonk Verifier** | `CAMRMEFTAFKUOVNFXX4BE2FD66SK2LLENREMNKOWDUNLKFVYJVG36QO7` | [View on Stellar Expert →](https://stellar.expert/explorer/testnet/contract/CAMRMEFTAFKUOVNFXX4BE2FD66SK2LLENREMNKOWDUNLKFVYJVG36QO7) |

> **Note:** After running `./deploy-testnet.sh`, contract addresses will be displayed and saved to `app/.env.local`

---

## Installation

### **Prerequisites**

```bash
# Install Stellar CLI
cargo install --locked stellar-cli --features opt

# Install Noir (nargo)
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
noirup

# Install Node.js dependencies
bun install  # or npm install
```

### **1. Deploy to Stellar Testnet**

```bash
# Generate and fund a testnet account
stellar keys generate your-testnet-identity
stellar keys fund your-testnet-identity --network testnet

# Set environment variable
export STELLAR_SOURCE_ACCOUNT=your-testnet-identity

# Deploy all contracts (circuit + verifier + game)
cd contracts
./deploy-testnet.sh
```

This script will:
- ✅ Compile the Noir circuit
- ✅ Generate verification key
- ✅ Build and deploy UltraHonk verifier contract
- ✅ Build and deploy Trap Grid game contract
- ✅ Initialize contracts with Game Hub integration
- ✅ Save addresses to `app/.env.local`

### **2. Run Frontend** (⚠️IN PRGRESS)

```bash
cd app
bun install  # or npm install
bun dev      # or npm run dev
```

Open [http://localhost:5678](http://localhost:5678)


### **3. Local Development (Optional)**

For faster iteration without testnet:

```bash
# Start local Stellar node
docker run -d -p 8000:8000 stellar/quickstart \
  --local \
  --limits unlimited \
  --enable core,rpc,lab,horizon,friendbot

# Configure local network
stellar network add local \
  --rpc-url http://localhost:8000/soroban/rpc \
  --network-passphrase "Standalone Network ; February 2017"

stellar network use local
stellar keys generate --global alice
stellar keys fund alice --network local

# Deploy to local
cd contracts
./deploy-local.sh
```


### **4-1. Test End-to-End** (on `Stellar Local Network`)
(NOTE: In advance, running the Docker, which is subsequently introduced at the `step 3` above, would be required)

```bash
cd scripts/e2e/stellar-local-network

# Test both the position-movement circuit & the trap-merkle-root circuit based on-chain verification (on `Stellar Local Network`)
sh test-local_trap-grid_all-circuits.sh
```


### **4-2. Test End-to-End** (on `Stellar Testnet`)

```bash
cd scripts/e2e/stellar-testnet

# Test position-movement circuit based on-chain verification (on `Stellar Testnet`)
sh test-verification_trap-grid_position-movement-circuit.sh
```

NOTE: Since the [**limit of the resource usage** for `Stellar Testnet` is `400M`](https://discord.com/channels/897514728459468821/1270442468428480583/1474055188535972028), the on-chain ZK Proof verification for the following circuits on `Stellar Testnet` are failed.

- The `trap-merkle-root` circuit: Running the e2e test using the `test-verification_trap-grid_trap-merkle-root-circuit.sh`

- Entire e2e test including both the `position-movement` circuit and the `trap-merkle-root` circuit: Running it using the `test-verification_trap-grid_all-circuits.sh`


## DEMO Video

- In this DEMO video, the `e2e` test of the `position-movement` circuit based on-chain verification (on `Stellar Testnet`) is demonstrated:  
   https://www.loom.com/share/28474b7898aa4e22b409c98e3ab564df



---

## Project Structure

```
ZK-trap-grid/
├── circuits/                          # Noir ZK circuits
│   ├── position-movement/             # ✅ Deployed circuit
│   │   ├── src/main.nr               # Circuit logic
│   │   ├── target/                   # Compiled artifacts
│   │   └── rs-soroban-ultrahonk/     # Verifier contract
│   ├── trap-commitment/              # Commitment-based circuit
│   └── trap-merkle-root/             # Merkle tree circuit
│
├── contracts/                         # Soroban smart contracts
│   ├── trap-grid/                    # Main game contract
│   │   └── src/lib.rs
│   ├── mock-game-hub/                # Local testing mock
│   ├── deploy-testnet.sh             # Testnet deployment
│   └── deploy-local.sh               # Local deployment
│
├── app/                               # Next.js frontend
│   ├── src/
│   │   ├── app/
│   │   │   ├── defender/             # Defender UI
│   │   │   └── attacker/             # Attacker UI
│   │   ├── components/
│   │   │   ├── Grid.tsx              # Interactive trap grid
│   │   │   ├── DefenderUI.tsx
│   │   │   └── AttackerUI.tsx
│   │   ├── lib/
│   │   │   ├── zkProof.ts            # Proof generation
│   │   │   ├── stellar.ts            # Blockchain calls
│   │   │   └── poseidon.ts           # Hashing
│   │   └── providers/
│   │       └── WalletProviderWrapper.tsx
│   ├── public/circuits/              # Circuit JSON artifacts
│   └── package.json
│
└── scripts/                           # Testing scripts
    └── e2e/
        ├── stellar-testnet/          # Testnet E2E tests
        └── stellar-local-network/    # Local E2E tests
```

---

## References

### **Noir (zkDSL) powered by Aztec**
- [Noir Language](https://noir-lang.org/) - Zero-knowledge circuit language
- [Noir Documentation](https://noir-lang.org/docs) - Noir guides and references
- [UltraHonk Proving System](https://github.com/AztecProtocol/aztec-packages/tree/master/barretenberg) - Efficient ZK-SNARK system
- [Aztec bb.js](https://www.npmjs.com/package/@aztec/bb.js) - JavaScript library for proof generation


### **Stellar**

- [Noir on Stellar Tutorial](https://jamesbachini.com/noir-on-stellar/) by James Bachini - Comprehensive guide

- [Stellar Documentation](https://developers.stellar.org/) - Stellar blockchain docs
- [Soroban Smart Contracts](https://soroban.stellar.org/) - Smart contract platform
- [Stellar CLI Reference](https://developers.stellar.org/docs/tools/developer-tools/cli) - Command-line tools

- [Game Hub Contract](https://stellar.expert/explorer/testnet/contract/CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG) - Official Game Hub on Stellar Expert

