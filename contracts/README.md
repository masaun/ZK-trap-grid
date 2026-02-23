# ZK Trap Grid - Smart Contracts 🔐

Soroban smart contracts for the ZK Trap Grid game on Stellar blockchain, which work with the **`Noir` ZK circuit**.

## Overview

This directory contains the Soroban smart contracts that power the ZK Trap Grid game:

- 🎮 **Trap Grid Contract** - Main game logic and state management
- ✅ **UltraHonk Verifier Contract** - On-chain ZK proof verification
- 🧪 **Mock Game Hub Contract** - Local testing mock (testnet uses official hub)

All contracts are written in Rust using the Soroban SDK and deployed on Stellar Testnet.

---

## 🎯 Technical components

| Technical component | Implementation | Status |
|------------|----------------|--------|
| **On-chain State** | All game state stored in Stellar Testnet | ✅ |
| **Game Hub Integration** | Calls official hub `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG` | ✅ |
| **ZK Verification** | On-chain UltraHonk proof verification | ✅ |
| **Frontend dApp** | Full Next.js dApp with wallet integration | ⚠️ IN PROGRESS |

---

## Quick Start

### **Prerequisites**

```bash
# Install Stellar CLI
cargo install --locked stellar-cli --features opt

# Install Nargo (Noir compiler)
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
noirup

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup target add wasm32-unknown-unknown
```

### **Deploy to Stellar Testnet**

```bash
# 1. Generate and fund testnet account
stellar keys generate your-testnet-identity
stellar keys fund your-testnet-identity --network testnet

# 2. Set environment variable
export STELLAR_SOURCE_ACCOUNT=your-testnet-identity

# 3. Deploy all contracts
./deploy-testnet.sh
```

This will:
- ✅ Build the Position Movement circuit
- ✅ Generate verification key
- ✅ Deploy UltraHonk verifier contract
- ✅ Deploy Trap Grid game contract
- ✅ Initialize with Game Hub integration
- ✅ Save addresses to `../app/.env.local`

### **Deploy Locally (Development)**

```bash
# 1. Start local Stellar node
docker run -d -p 8000:8000 stellar/quickstart \
  --local \
  --limits unlimited \
  --enable core,rpc,lab,horizon,friendbot

# 2. Configure local network
stellar network add local \
  --rpc-url http://localhost:8000/soroban/rpc \
  --network-passphrase "Standalone Network ; February 2017"
stellar network use local
stellar keys generate --global alice
stellar keys fund alice --network local

# 3. Deploy contracts
./deploy-local.sh
```

---

## Contract Architecture

### **System Overview**

```
┌─────────────────────────────────────────────────────────────┐
│                    Trap Grid Contract                        │
│  • Game state management                                     │
│  • Player registration                                       │
│  • Move validation                                           │
│  • Score tracking                                            │
└──────────────┬──────────────────┬───────────────────────────┘
               │                  │
               │ verify()         │ start_game() / end_game()
               │                  │
    ┌──────────▼────────┐   ┌─────▼──────────────────┐
    │  Verifier Contract │   │  Game Hub Contract     │
    │  (UltraHonk)       │   │  (Official)  │
    │  • VK storage      │   │  • Session registry    │
    │  • Proof verify    │   │  • Global leaderboard  │
    └────────────────────┘   └────────────────────────┘
```

### **Contract Interactions**

1. **Defender** calls `start_game()` → Trap Grid → Game Hub (registers session)
2. **Attacker** calls `make_move()` → Trap Grid (records move)
3. **Defender** generates proof off-chain → calls `make_move()` with proof
4. **Trap Grid** calls `verify()` → Verifier (validates proof)
5. If valid → update game state (hit/miss)
6. **Either player** calls `end_game()` → Trap Grid → Game Hub (finalize scores)

---

## Contracts

### **1. Trap Grid Contract**

**Location:** [trap-grid/src/lib.rs](trap-grid/src/lib.rs)

#### **Key Functions**

```rust
// Initialize contract
pub fn __constructor(
    env: Env,
    admin: Address,
    game_hub: Address,
    verifier: Address
)

// Start new game session
pub fn start_game(
    env: Env,
    session_id: u32,
    defender: Address,
    attacker: Address
) -> Result<(), Error>

// Make a move (with optional proof)
pub fn make_move(
    env: Env,
    session_id: u32,
    x: u32,
    y: u32,
    proof: Option<Bytes>,
    public_inputs: Option<Bytes>
) -> Result<bool, Error>

// End game and finalize scores
pub fn end_game(
    env: Env,
    session_id: u32
) -> Result<(), Error>

// Query game state
pub fn get_game(
    env: Env,
    session_id: u32
) -> Result<Game, Error>
```

#### **Data Structures**

```rust
pub struct Game {
    pub defender: Address,        // Player A
    pub attacker: Address,        // Player B
    pub defender_points: i128,
    pub attacker_points: i128,
    pub moves_made: u32,
    pub hits: u32,
    pub misses: u32,
    pub game_started: bool,
    pub game_ended: bool,
    pub winner: Option<Address>,
}

pub struct Move {
    pub x: u32,
    pub y: u32,
    pub is_hit: bool,
    pub verified: bool,
}
```

#### **Game Logic**

| Action | Who | Requirements | Result |
|--------|-----|--------------|--------|
| **Start Game** | Defender | Valid attacker address | Game session created, Game Hub notified |
| **Make Move** | Attacker | Valid coordinates (0-7) | Move recorded, awaiting proof |
| **Submit Proof** | Defender | Valid ZK proof | Move verified, hit/miss recorded |
| **End Game** | Either | All moves complete | Winner determined, Game Hub updated |

### **2. UltraHonk Verifier Contract**

**Location:** [../circuits/position-movement/rs-soroban-ultrahonk/](../circuits/position-movement/rs-soroban-ultrahonk/)

#### **Function**

```rust
pub fn verify(
    env: Env,
    proof: Bytes,           // ZK proof bytes
    public_inputs: Bytes    // Public inputs
) -> bool
```

#### **Verification Process**

1. Decode proof bytes (UltraHonk format)
2. Extract public inputs
3. Load verification key (VK) from contract storage
4. Run UltraHonk verification algorithm
5. Return `true` if valid, `false` otherwise

#### **Proof Details**

- **Size:** ~2144 bytes
- **Algorithm:** UltraHonk with Keccak transcript
- **Circuit:** Position Movement (see [circuits/position-movement/](../circuits/position-movement/))

### **3. Mock Game Hub Contract**

**Location:** [mock-game-hub/src/lib.rs](mock-game-hub/src/lib.rs)

**Purpose:** Local testing only. Testnet deployments use the official Game Hub at `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG`.

#### **Functions**

```rust
pub fn register_game(
    env: Env,
    game_contract: Address,
    game_name: String,
    description: String
) -> u32

pub fn start_game(
    env: Env,
    game_id: Address,
    session_id: u32,
    player1: Address,
    player2: Address,
    player1_points: i128,
    player2_points: i128,
)

pub fn end_game(
    env: Env,
    session_id: u32,
    player1_won: bool
)
```

---

## Game Hub Integration

### **Official Game Hub**

**Contract Address:** `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG`

The Trap Grid contract integrates with the official Game Hub contract for:
- ✅ Session management
- ✅ Global leaderboard
- ✅ Player statistics
- ✅ Game discovery

### **Interface**

```rust
#[contractclient(name = "GameHubClient")]
pub trait GameHub {
    fn start_game(
        env: Env,
        game_id: Address,        // Trap Grid contract address
        session_id: u32,         // Unique session ID
        player1: Address,        // Defender
        player2: Address,        // Attacker
        player1_points: i128,    // Initial defender points
        player2_points: i128,    // Initial attacker points
    );

    fn end_game(
        env: Env,
        session_id: u32,
        player1_won: bool        // true if defender won
    );
}
```

### **Call Flow**

```
Defender → Trap Grid.start_game()
           └─> Game Hub.start_game() ✅ Registered

[Gameplay happens...]

Player → Trap Grid.end_game()
         └─> Game Hub.end_game() ✅ Scores recorded
```

---

## ZK Circuit Integration

### **Circuit: Position Movement**

**Location:** [../circuits/position-movement/](../circuits/position-movement/)

#### **What It Proves**

Proves that a move at coordinates (x, y) is a hit or miss **without revealing** the entire trap grid.

#### **Circuit Inputs**

```noir
// Public inputs (visible on-chain)
pub struct PublicInputs {
    move_x: u32,      // X coordinate (0-7)
    move_y: u32,      // Y coordinate (0-7)
    is_hit: u32,      // Claimed result: 0=miss, 1=hit
}

// Private inputs (secret to defender)
struct PrivateInputs {
    trap_value: u32   // Actual trap value at (x,y): 0 or 1
}
```

#### **Constraints**

```noir
// 1. Validate coordinates are within grid
assert(move_x >= 0 && move_x < 8);
assert(move_y >= 0 && move_y < 8);

// 2. Ensure trap_value is boolean
assert(trap_value == 0 || trap_value == 1);

// 3. Ensure claimed result matches actual trap value
assert(trap_value == is_hit);
```

#### **Proof Generation**

See [../circuits/position-movement/README.md](../circuits/position-movement/README.md) for circuit details.

---

## Deployment Scripts

### **deploy-testnet.sh**

Deploys to Stellar Testnet with official Game Hub integration.

**Steps:**
1. Build Position Movement circuit
2. Generate verification key
3. Build and deploy UltraHonk verifier
4. Build and deploy Trap Grid contract
5. Initialize Trap Grid with Game Hub address
6. Save contract addresses to `../app/.env.local`

**Usage:**
```bash
export STELLAR_SOURCE_ACCOUNT=your-testnet-identity
./deploy-testnet.sh
```

### **deploy-local.sh**

Deploys to local Stellar network with mock Game Hub.

**Steps:**
1. Build Position Movement circuit
2. Deploy mock Game Hub
3. Deploy UltraHonk verifier
4. Deploy Trap Grid contract
5. Initialize and register game

**Usage:**
```bash
# After starting local network
./deploy-local.sh
```

### **setup.sh**

Sets up frontend with circuit artifacts (deprecated - use deploy scripts).

---

## Development

### **Build Contracts**

```bash
# Build all contracts
cargo build --target wasm32-unknown-unknown --release

# Build specific contract
cd trap-grid
cargo build --target wasm32-unknown-unknown --release
```

### **Run Tests**

```bash
# Run all tests
cargo test

# Run specific contract tests
cd trap-grid
cargo test

# Run with output
cargo test -- --nocapture
```

### **Deploy Individual Contracts**

```bash
# Deploy verifier
stellar contract deploy \
  --wasm ../circuits/position-movement/rs-soroban-ultrahonk/target/wasm32v1-none/release/rs_soroban_ultrahonk.wasm \
  --source-account $STELLAR_SOURCE_ACCOUNT \
  --network testnet \
  -- \
  --vk_bytes-file-path ../circuits/position-movement/target/vk

# Deploy trap-grid
stellar contract deploy \
  --wasm target/wasm32-unknown-unknown/release/trap_grid.wasm \
  --source-account $STELLAR_SOURCE_ACCOUNT \
  --network testnet

# Initialize trap-grid
stellar contract invoke \
  --id <TRAP_GRID_ID> \
  --source-account $STELLAR_SOURCE_ACCOUNT \
  --network testnet \
  -- \
  __constructor \
  --admin <ADMIN_ADDRESS> \
  --game_hub CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG \
  --verifier <VERIFIER_ID>
```

---

## Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Smart Contracts** | Rust + Soroban SDK | Contract logic |
| **ZK Verifier** | rs-soroban-ultrahonk | On-chain proof verification |
| **ZK Circuit** | Noir | Zero-knowledge circuit |
| **Blockchain** | Stellar (Testnet) | Decentralized ledger |
| **Build Tool** | Cargo | Rust build system |
| **CLI** | stellar-cli | Contract deployment |

---

## Project Structure

```
contracts/
├── Cargo.toml                    # Workspace manifest
├── deploy-testnet.sh             # Testnet deployment script
├── deploy-local.sh               # Local deployment script
├── setup.sh                      # Frontend setup (deprecated)
├── README.md                     # This file
│
├── trap-grid/                    # Main game contract
│   ├── Cargo.toml
│   └── src/
│       └── lib.rs                # Contract implementation
│
├── mock-game-hub/                # Mock hub for local dev
│   ├── Cargo.toml
│   └── src/
│       └── lib.rs
│
└── target/                       # Build artifacts
    └── wasm32-unknown-unknown/
        └── release/
            ├── trap_grid.wasm    # Trap Grid WASM
            └── mock_game_hub.wasm
```

---

## Contract Addresses

### **Stellar Testnet**

| Contract | Address | Explorer |
|----------|---------|----------|
| **Game Hub (Official)** | `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG` | [View →](https://stellar.expert/explorer/testnet/contract/CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG) |
| **Trap Grid** | Run `./deploy-testnet.sh` | Will be displayed after deployment |
| **Verifier** | Run `./deploy-testnet.sh` | Will be displayed after deployment |

> **Note:** After deployment, addresses are saved to `../app/.env.local`

---

## Troubleshooting

### **Deployment Issues**

**Problem:** `STELLAR_SOURCE_ACCOUNT not set`
```bash
export STELLAR_SOURCE_ACCOUNT=your-testnet-identity
stellar keys fund your-testnet-identity --network testnet
```

**Problem:** `stellar command not found`
```bash
cargo install --locked stellar-cli --features opt
```

**Problem:** `nargo command not found`
```bash
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
noirup
```

### **Build Issues**

**Problem:** `wasm32-unknown-unknown` target not found
```bash
rustup target add wasm32-unknown-unknown
```

**Problem:** Build fails with memory errors
```bash
# Increase stack size
export RUST_MIN_STACK=8388608
cargo build --release
```

### **Contract Invocation Issues**

**Problem:** Transaction simulation fails
```
Solution:
1. Check contract is initialized
2. Verify function parameters
3. Ensure caller has permission
4. Check account balance for fees
```

**Problem:** Proof verification fails
```
Solution:
1. Verify VK matches circuit
2. Check proof format (UltraHonk)
3. Validate public inputs
4. Ensure circuit constraints are satisfied
```

---

## Resources

### **Documentation**
- [Soroban Documentation](https://soroban.stellar.org/docs) - Smart contract guide
- [Stellar CLI Reference](https://developers.stellar.org/docs/tools/developer-tools/cli) - CLI commands
- [Rust Soroban SDK](https://docs.rs/soroban-sdk/latest/soroban_sdk/) - SDK API reference
- [Game Hub Contract](https://stellar.expert/explorer/testnet/contract/CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG) - Official hub

### **ZK Technology**
- [Noir Language](https://noir-lang.org/) - ZK circuit language
- [UltraHonk](https://github.com/AztecProtocol/aztec-packages/tree/master/barretenberg) - Proving system
- [rs-soroban-ultrahonk](https://github.com/TechySauce/rs-soroban-ultrahonk) - Soroban verifier
