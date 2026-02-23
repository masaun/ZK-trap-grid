# ZK Trap Grid Game on Stellar

A two-player zero-knowledge proof game built for the [Stellar Hacks ZK Gaming](https://dorahacks.io/hackathon/stellar-hacks-zk-gaming) hackathon.

## Game Overview

**Trap Grid** is a strategic ZK game where:
- **Defender (Player A)** sets up a hidden 8×8 trap grid
- **Attacker (Player B)** makes moves to discover traps
- **Defender** proves hit/miss results using ZK proofs without revealing all trap positions
- All verification happens **on-chain** using UltraHonk proofs on Stellar

## 🎯 Hackathon Compliance

This game meets all Stellar Hacks ZK Gaming requirements:

✅ **On-chain state:** All game state stored on Stellar Testnet  
✅ **Game Hub integration:** Calls official game hub contract `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG`  
✅ **ZK verification:** On-chain proof verification using UltraHonk  
✅ **Frontend dApp:** Full game interface with wallet integration

## Quick Start

### Deploy to Stellar Testnet

```bash
cd contracts

# Set your testnet account
export STELLAR_SOURCE_ACCOUNT=your-testnet-identity

# Deploy (builds circuit, verifier, and game contract)
./deploy-testnet.sh
```

### Run Frontend

```bash
cd app
npm install
npm run dev
```

Visit http://localhost:5678 to play!

## Architecture

## Project Structure

Visit http://localhost:5678 to play!

## Project Structure

```
.
├── contracts/
│   ├── trap-grid/           # Main game contract (integrates with Game Hub)
│   └── mock-game-hub/       # Local dev mock (testnet uses real hub)
├── app/                     # Next.js frontend
│   ├── src/
│   │   ├── components/      # UI components (DefenderUI, AttackerUI)
│   │   ├── lib/            # ZK proof generation, Stellar SDK
│   │   └── providers/      # Wallet integration
│   └── public/circuits/    # Circuit artifacts
├── circuits/               # Noir ZK circuits
│   ├── position-movement/  # Position movement circuit
│   ├── trap-commitment/    # Trap commitment circuit
│   └── trap-merkle-root/   # Merkle root circuit
└── docs/                   # Documentation
```

Deployment scripts are in `contracts/`:
- `deploy-local.sh` - Local deployment (uses mock hub)
- `deploy-testnet.sh` - Testnet deployment (uses real hub)
- `setup.sh` - Setup frontend with circuit artifacts

## Game Hub Integration

The trap-grid contract integrates with the **official hackathon Game Hub** deployed at:

```
CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG
```

### Game Hub Interface

```rust
#[contractclient(name = "GameHubClient")]
pub trait GameHub {
    fn start_game(
        env: Env,
        game_id: Address,        // Address of the game contract
        session_id: u32,
        player1: Address,        // Defender
        player2: Address,        // Attacker
        player1_points: i128,
        player2_points: i128,
    );

    fn end_game(
        env: Env,
        session_id: u32,
        player1_won: bool        // true if player1 (defender) won
    );
}
```

### When Called

- **`start_game()`** - Called when defender starts a new game session
- **`end_game()`** - Called after all moves are made and winner is determined

## ZK Circuit

**Circuit:** `trap-grid-position-movement`  
**Location:** `../trap-grid/trap-grid-position-movement/`

### Circuit Logic
```noir
// Private inputs
trap_value: Field         // 0 or 1 (no trap or trap)

// Public inputs
position_x: u8           // X coordinate (0-7)
position_y: u8           // Y coordinate (0-7)
is_hit: bool             // Claimed hit/miss result

// Verification
commitment = poseidon_hash_1([trap_value])
assert(is_hit == (trap_value == 1))
```

### Proof System
- **Proving System:** UltraHonk with Keccak transcript
- **Proof Size:** ~2144 bytes
- **Verification:** On-chain in Soroban contract
- **Cryptographic Hash:** Poseidon

## Deployment

### Testnet (Production)

Uses **official Game Hub contract** for hackathon submission:

```bash
# Set your identity
export STELLAR_SOURCE_ACCOUNT=your-testnet-identity

# Deploy everything
./deploy-testnet.sh
```

See [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions.

### Local Development

Uses **mock Game Hub** for testing:

```bash
# Start local network (separate terminal)
stellar network start

# Deploy
./deploy-local.sh
```

## Technology Stack

### Smart Contracts
- **Language:** Rust (Soroban SDK)
- **ZK Verifier:** rs-soroban-ultrahonk
- **Network:** Stellar Testnet

### ZK Circuit
- **Language:** Noir
- **Compiler:** Nargo
- **Proving System:** UltraHonk (bb.js)

### Frontend
- **Framework:** Next.js 15 (App Router)
- **Wallet:** Stellar Wallet Kit 2.0
- **Styling:** Tailwind CSS
- **ZK:** @noir-lang/noir_js, @aztec/bb.js

## Documentation

- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Complete deployment instructions
- [docs/IMPLEMENTATION_SUMMARY.md](docs/IMPLEMENTATION_SUMMARY.md) - Technical implementation details
- [docs/TRAP_GRID_README.md](docs/TRAP_GRID_README.md) - Game mechanics and rules
- [docs/QUICKSTART.md](docs/QUICKSTART.md) - Quick start guide
- [WALLET_INTEGRATION.md](WALLET_INTEGRATION.md) - Wallet integration details

## Resources

- **Hackathon:** https://dorahacks.io/hackathon/stellar-hacks-zk-gaming
- **Stellar Docs:** https://developers.stellar.org
- **Noir Docs:** https://noir-lang.org
- **UltraHonk:** https://github.com/TechySauce/rs-soroban-ultrahonk
- **Stellar Wallet Kit:** https://www.npmjs.com/package/stellar-wallet-kit

## License

MIT License - See LICENSE file

---

**Built for Stellar Hacks ZK Gaming Hackathon** 🎮⚡
