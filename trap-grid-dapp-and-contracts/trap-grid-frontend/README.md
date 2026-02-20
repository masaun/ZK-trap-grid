# ZK Trap Grid Frontend

A Next.js frontend for the ZK Trap Grid game on Stellar blockchain.

## Features

- **Two-UI Demo**: Separate interfaces for Defender (Player A) and Attacker (Player B)
- **Wallet Integration**: Freighter wallet support
- **Interactive Grid**: 8x8 trap grid with visual feedback
- **ZK Proof Integration**: Generates and verifies zero-knowledge proofs
- **Real-time Updates**: Monitors on-chain game state

## Tech Stack

- **Next.js 15** - React framework
- **TypeScript** - Type safety
- **TailwindCSS** - Styling
- **Stellar SDK** - Blockchain interaction
- **Freighter API** - Wallet connection

## Quick Start

1. **Install dependencies**:
   ```bash
   npm install
   # or
   bun install
   ```

2. **Configure environment**:
   Copy contract addresses to `.env.local`:
   ```bash
   cp ../.contract-addresses.env .env.local
   ```

3. **Run development server**:
   ```bash
   npm run dev
   # or
   bun dev
   ```

4. **Open browser**:
   Navigate to [http://localhost:3000](http://localhost:3000)

## Pages

- **`/`** - Home page with game explanation
- **`/defender`** - Player A interface (set traps, start game)
- **`/attacker`** - Player B interface (make moves, view results)

## Environment Variables

Required variables in `.env.local`:

```env
NEXT_PUBLIC_NETWORK_PASSPHRASE=Standalone Network ; February 2017
NEXT_PUBLIC_RPC_URL=http://localhost:8000/soroban/rpc
NEXT_PUBLIC_GAME_HUB_CONTRACT=<game-hub-contract-id>
NEXT_PUBLIC_TRAP_GRID_CONTRACT=<trap-grid-contract-id>
NEXT_PUBLIC_VERIFIER_CONTRACT=<verifier-contract-id>
```

## Development

### Project Structure

```
src/
├── app/              # Next.js pages
│   ├── page.tsx      # Home page
│   ├── defender/     # Defender UI page
│   └── attacker/     # Attacker UI page
├── components/       # React components
│   ├── Grid.tsx      # Grid display component
│   ├── DefenderUI.tsx
│   ├── AttackerUI.tsx
│   └── WalletConnect.tsx
├── lib/              # Utilities
│   ├── config.ts     # Configuration
│   ├── utils.ts      # Helper functions
│   ├── stellar.ts    # Stellar SDK integration
│   └── zkProof.ts    # ZK proof generation
└── types/            # TypeScript types
    └── index.ts
```

### Key Components

#### Grid Component

Displays the 8x8 game grid with different states:
- Empty cells (gray)
- Trap cells (💣 - defender only)
- Hit cells (💥)
- Miss cells (❌)

#### DefenderUI Component

Allows Player A to:
1. Set trap positions
2. Generate Merkle root commitment
3. Start game with attacker address
4. Monitor game progress

#### AttackerUI Component

Allows Player B to:
1. Join game by session ID
2. Make moves by clicking grid cells
3. View move history
4. Check game status

### Stellar Integration

The app uses `@stellar/stellar-sdk` to:
- Connect to Stellar RPC
- Build transactions
- Invoke smart contracts
- Query game state

### ZK Proof Generation

Located in `lib/zkProof.ts`. Currently uses placeholder implementation.

To integrate real proof generation:
1. Install `@noir-lang/noir_js` and `@noir-lang/backend_barretenberg`
2. Copy circuit artifacts to `public/circuits/`
3. Implement `generateProof()` function

## Building for Production

```bash
npm run build
npm start
```

Or with Docker:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

## Troubleshooting

### Wallet Issues

- Ensure Freighter is installed and unlocked
- Switch network to "Standalone" for local development
- Fund accounts using friendbot

### Contract Connection

- Verify `.env.local` has correct contract addresses
- Check Stellar network is accessible
- Ensure contracts are deployed

### Build Errors

- Clear `.next` folder: `rm -rf .next`
- Reinstall dependencies: `rm -rf node_modules && npm install`
- Check Node.js version: `node --version` (should be 18+)

## License

MIT
