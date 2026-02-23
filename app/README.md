# ZK Trap Grid Frontend 🎮 (⚠️IN PROGRESS⚠️)

## Overview

This dApp provides a complete user interface for playing ZK Trap Grid, featuring:

- 🛡️ **Defender Interface** - Set traps, generate proofs, and defend your grid
- ⚔️ **Attacker Interface** - Make strategic moves and discover hidden traps
- 🔐 **Client-Side ZK Proofs** - Generate UltraHonk proofs directly in the browser
- 👛 **Wallet Integration** - Connect with Freighter or other Stellar wallets
- ⛓️ **Real-time Blockchain State** - Monitor game progress on Stellar Testnet

---

## Features

| Feature | Description |
|---------|-------------|
| **Dual UI System** | Separate pages for Defender (`/defender`) and Attacker (`/attacker`) |
| **Interactive 8×8 Grid** | Click-to-place traps, visual feedback for hits/misses |
| **ZK Proof Generation** | Client-side proof generation using `@aztec/bb.js` |
| **Wallet Support** | Freighter wallet and stellar-wallet-kit integration |
| **Transaction Building** | Automatic Stellar transaction construction and signing |
| **Session Management** | Track multiple game sessions with unique IDs |
| **Responsive Design** | Mobile-friendly interface with TailwindCSS |
| **Type Safety** | Full TypeScript support with strict mode |

---

## Tech Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| **`@aztec/bb.js`** | 0.87.0 | ZK proof generation (UltraHonk) |
| **`@noir-lang/noir_js`** | 1.0.0-beta.11 | Noir circuit integration |
| **`poseidon-lite`** | 0.3.0 | Poseidon hash function |
| **@stellar/stellar-sdk** | 14.5.0 | Blockchain interactions |
| **@stellar/freighter-api** | 2.0.0 | Wallet connection |
| **stellar-wallet-kit** | 2.0.7 | Wallet UI components |
| **dayjs** | 1.11.13 | Date/time formatting |
| **Next.js** | 15.1.5 | React framework with App Router |
| **React** | 19.0.0 | UI components |
| **TypeScript** | 5.x | Type safety |
| **TailwindCSS** | 3.4.17 | Styling |

---

## Quick Start

### **1. Install Dependencies**

```bash
# Using bun (recommended)
bun install

# Or using npm
npm install

# Or using yarn
yarn install
```

### **2. Configure Environment**

Create `.env.local` in the `app/` directory:

```bash
# Stellar Testnet Configuration
NEXT_PUBLIC_NETWORK_PASSPHRASE=<your-network-passphrase>
NEXT_PUBLIC_RPC_URL=https://soroban-testnet.stellar.org

# Contract Addresses (from deploy-testnet.sh output)
NEXT_PUBLIC_GAME_HUB_CONTRACT=CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG
NEXT_PUBLIC_TRAP_GRID_CONTRACT=<your-trap-grid-contract-id>
NEXT_PUBLIC_VERIFIER_CONTRACT=CAMRMEFTAFKUOVNFXX4BE2FD66SK2LLENREMNKOWDUNLKFVYJVG36QO7
```

**Option A:** Auto-generate by deploying contracts (recommended):
```bash
cd ../contracts
./deploy-testnet.sh
# Addresses will be saved to app/.env.local automatically
```

**Option B:** Manual configuration:
```bash
cp .env.example .env.local
# Edit .env.local with your contract addresses
```

### **3. Copy Circuit Artifacts**

```bash
# Copy compiled circuit to public directory
cp ../circuits/position-movement/target/position_movement.json \
   public/circuits/trap_grid_position_movement.json
```

### **4. Run Development Server**

```bash
bun dev
# Or: npm run dev
```

Open [http://localhost:5678](http://localhost:5678) in your browser.

---

## Application Structure

### **Pages**

| Route | Component | Purpose |
|-------|-----------|---------|
| `/` | [page.tsx](src/app/page.tsx) | Home page with game explanation and links |
| `/defender` | [defender/page.tsx](src/app/defender/page.tsx) | Defender interface (Player A) |
| `/attacker` | [attacker/page.tsx](src/app/attacker/page.tsx) | Attacker interface (Player B) |

### **Components**

```
src/components/
├── Grid.tsx              # Interactive 8×8 trap grid
├── DefenderUI.tsx        # Defender game controls
├── AttackerUI.tsx        # Attacker game controls
└── WalletConnect.tsx     # Wallet connection button
```

#### **Grid Component**

Displays the game grid with different cell states:

```tsx
<Grid
  gridData={[0, 1, 0, ...]}  // 64-element array (0=empty, 1=trap)
  onCellClick={(x, y) => {...}}
  showTraps={isDefender}     // Only defender sees traps
  moves={moveHistory}        // Show hit/miss markers
/>
```

**Cell Visualization:**
- 🟦 Empty cell (default)
- 💣 Trap cell (defender only)
- 💥 Hit (red background)
- ❌ Miss (gray marker)

#### **DefenderUI Component**

Features:
- Interactive grid for trap placement
- "Start Game" button with attacker address input
- Pending moves list
- "Generate Proof" button for each move
- Game statistics (hits, misses, moves remaining)

#### **AttackerUI Component**

Features:
- Join game by session ID
- Click grid cells to make moves
- Move history display
- Real-time game status updates

### **Library Functions**

```
src/lib/
├── config.ts         # Contract addresses and network config
├── stellar.ts        # Stellar SDK wrappers
├── zkProof.ts        # ZK proof generation
├── poseidon.ts       # Poseidon hashing utilities
├── defenderProof.ts  # Defender-specific proof logic
└── utils.ts          # Helper functions
```

#### **Key Functions**

**Stellar Interactions** (`stellar.ts`):
```typescript
// Initialize game
async function startGame(session_id, defender, attacker, merkle_root)

// Submit move
async function makeMove(session_id, x, y, proof?, public_inputs?)

// Query game state
async function getGameState(session_id)
```

**ZK Proof Generation** (`zkProof.ts`):
```typescript
// Generate proof for a move
async function generateMoveProof(
  trapValue: number,    // 0 or 1
  moveX: number,        // 0-7
  moveY: number,        // 0-7
  isHit: number         // 0 or 1
): Promise<{ proof: Uint8Array, publicInputs: string[] }>
```

**Poseidon Hashing** (`poseidon.ts`):
```typescript
// Hash grid to create Merkle root
function poseidonHash(inputs: bigint[]): bigint

// Compute trap grid commitment
function computeTrapCommitment(gridData: number[]): string
```

---

## Development Guide

### **Running Different Networks**

**Stellar Testnet** (default):
```bash
# .env.local
NEXT_PUBLIC_NETWORK_PASSPHRASE=Test SDF Network ; September 2015
NEXT_PUBLIC_RPC_URL=https://soroban-testnet.stellar.org
```

**Local Stellar Network**:
```bash
# Start local node first
docker run -d -p 8000:8000 stellar/quickstart --local --enable soroban

# .env.local
NEXT_PUBLIC_NETWORK_PASSPHRASE=Standalone Network ; February 2017
NEXT_PUBLIC_RPC_URL=http://localhost:8000/soroban/rpc
```

### **Wallet Integration**

The app uses [stellar-wallet-kit](https://github.com/Creit-Tech/Stellar-Wallets-Kit) for multi-wallet support:

```tsx
import { WalletProviderWrapper } from '@/providers/WalletProviderWrapper'

function App() {
  return (
    <WalletProviderWrapper>
      {/* Your app */}
    </WalletProviderWrapper>
  )
}
```

**Connect Wallet:**
```typescript
import { useStellarWallet } from 'stellar-wallet-kit'

const { connect, publicKey, disconnect } = useStellarWallet()

// Connect
await connect()

// Get address
console.log(publicKey)

// Disconnect
disconnect()
```

### **Building Transactions**

Example transaction flow:

```typescript
import { Contract, SorobanRpc } from '@stellar/stellar-sdk'

// 1. Build operation
const contract = new Contract(TRAP_GRID_CONTRACT)
const operation = contract.call('make_move', session_id, x, y)

// 2. Create transaction
const transaction = new TransactionBuilder(account, { fee: '1000' })
  .addOperation(operation)
  .setTimeout(30)
  .build()

// 3. Simulate
const simulated = await server.simulateTransaction(transaction)

// 4. Sign with wallet
const signedTx = await signTransaction(simulated.toXDR())

// 5. Submit
const result = await server.sendTransaction(signedTx)
```

### **ZK Proof Generation Flow**

```typescript
import { BarretenbergBackend } from '@aztec/bb.js'
import { Noir } from '@noir-lang/noir_js'

// 1. Load circuit
const circuit = await fetch('/circuits/trap_grid_position_movement.json')
  .then(r => r.json())

// 2. Create backend
const backend = new BarretenbergBackend(circuit)
const noir = new Noir(circuit, backend)

// 3. Prepare inputs
const inputs = {
  public_inputs: {
    move_x: 3,
    move_y: 4,
    is_hit: 1
  },
  private_inputs: {
    trap_value: 1
  }
}

// 4. Generate proof
const proof = await noir.generateProof(inputs)

// 5. Extract proof bytes
const proofBytes = proof.proof // Uint8Array
const publicInputs = proof.publicInputs
```

---

## API Reference

### **Environment Variables**

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `NEXT_PUBLIC_NETWORK_PASSPHRASE` | ✅ | Stellar network passphrase | `Test SDF Network ; September 2015` |
| `NEXT_PUBLIC_RPC_URL` | ✅ | Soroban RPC endpoint | `https://soroban-testnet.stellar.org` |
| `NEXT_PUBLIC_GAME_HUB_CONTRACT` | ✅ | Game Hub contract address | `CB4VZAT...` |
| `NEXT_PUBLIC_TRAP_GRID_CONTRACT` | ✅ | Trap Grid contract address | `CAXYZ...` |
| `NEXT_PUBLIC_VERIFIER_CONTRACT` | ✅ | Verifier contract address | `CBUVW...` |

### **Type Definitions**

See [src/types/index.ts](src/types/index.ts) for full type definitions:

```typescript
interface GameState {
  defender: string
  attacker: string
  moves_made: number
  hits: number
  misses: number
  game_started: boolean
  game_ended: boolean
  winner: string | null
}

interface Move {
  x: number
  y: number
  is_hit: boolean
  verified: boolean
}

interface ProofData {
  proof: Uint8Array
  public_inputs: string[]
}
```

---

## Building for Production

### **Next.js Build**

```bash
# Build optimized production bundle
bun run build

# Start production server
bun start

# Or combine
bun run build && bun start
```

### **Docker Deployment**

```dockerfile
FROM oven/bun:1 AS base
WORKDIR /app

# Install dependencies
COPY package.json bun.lockb ./
RUN bun install --frozen-lockfile

# Copy source
COPY . .

# Build
RUN bun run build

# Production
FROM oven/bun:1-slim
WORKDIR /app
COPY --from=base /app/.next ./.next
COPY --from=base /app/node_modules ./node_modules
COPY --from=base /app/package.json ./package.json
COPY --from=base /app/public ./public

EXPOSE 5678
ENV PORT 5678
CMD ["bun", "start"]
```

Build and run:
```bash
docker build -t zk-trap-grid-frontend .
docker run -p 5678:5678 zk-trap-grid-frontend
```

### **Static Export** (optional)

For static hosting (no SSR):

```js
// next.config.js
module.exports = {
  output: 'export',
  images: {
    unoptimized: true
  }
}
```

```bash
bun run build
# Outputs to ./out directory
```

---

## Troubleshooting

### **Wallet Connection Issues**

**Problem:** Freighter not detected
```
Solution:
1. Install Freighter extension: https://www.freighter.app/
2. Create/import account
3. Ensure extension is enabled
4. Refresh page
```

**Problem:** Wrong network selected
```
Solution:
1. Open Freighter settings
2. Switch to "Testnet" (or "Standalone" for local)
3. Reconnect wallet in app
```

**Problem:** Insufficient XLM balance
```
Solution:
# Fund testnet account
stellar keys fund <your-address> --network testnet
# Or use friendbot: https://friendbot.stellar.org/
```

### **Contract Interaction Issues**

**Problem:** "Contract not found" error
```
Solution:
1. Verify .env.local has correct CONTRACT addresses
2. Check contracts are deployed:
   stellar contract id asset --asset native --network testnet
3. Ensure network matches (local vs testnet)
```

**Problem:** Transaction simulation fails
```
Solution:
1. Check contract is initialized
2. Verify function parameters match contract signature
3. Increase fee: TransactionBuilder(..., { fee: '10000' })
4. Check account has sufficient balance
```

### **ZK Proof Generation Issues**

**Problem:** Circuit artifact not found
```
Solution:
1. Ensure circuit JSON is in public/circuits/
2. Check filename matches: trap_grid_position_movement.json
3. Rebuild circuit:
   cd ../circuits/position-movement
   nargo compile
   cp target/position_movement.json ../../app/public/circuits/
```

**Problem:** Proof generation takes too long
```
Solution:
1. Check browser console for memory errors
2. Use smaller test data
3. Ensure bb.js wasm is loaded correctly
4. Try in different browser (Chrome recommended)
```

**Problem:** Proof verification fails on-chain
```
Solution:
1. Verify VK in verifier contract matches circuit
2. Check public inputs are correctly formatted
3. Ensure proof bytes are not corrupted
4. Validate private inputs satisfy circuit constraints
```

### **Build Issues**

**Problem:** Module not found errors
```bash
# Clear cache and reinstall
rm -rf .next node_modules
bun install
```

**Problem:** Type errors
```bash
# Regenerate types
bun run build
# Or check tsconfig.json strict mode settings
```

**Problem:** Environment variables not available
```
Solution:
1. Variables must start with NEXT_PUBLIC_ for client-side
2. Restart dev server after changing .env.local
3. Check .env.local is in app/ directory (not root)
```

---

## Development Tips

### **Hot Reload Circuit Changes**

When modifying circuits:
```bash
# Terminal 1: Rebuild circuit on changes
cd ../circuits/position-movement
nargo compile && cp target/position_movement.json ../../app/public/circuits/

# Terminal 2: Run dev server
cd ../../app
bun dev
```

### **Debug Mode**

Enable verbose logging:
```typescript
// lib/config.ts
export const DEBUG = true

// Usage
if (DEBUG) console.log('Transaction XDR:', tx.toXDR())
```

### **Testing Locally**

```bash
# 1. Start local Stellar node
docker run -d -p 8000:8000 stellar/quickstart --local --enable soroban

# 2. Deploy contracts
cd ../contracts
./deploy-local.sh

# 3. Start frontend
cd ../app
bun dev
```

---

## Resources

- [Noir Language](https://noir-lang.org/docs)
- [Next.js Documentation](https://nextjs.org/docs)
- [Stellar SDK Docs](https://developers.stellar.org/docs/tools/sdks/library)
- [Freighter Wallet](https://www.freighter.app/)
- [TailwindCSS](https://tailwindcss.com/docs)



