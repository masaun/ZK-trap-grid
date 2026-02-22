# 🚀 Quick Start Guide - Trap Grid with Position Movement Circuit

Get up and running with the ZK Trap Grid game on Stellar in minutes!

## Prerequisites

Make sure you have installed:
- ✅ [Stellar CLI](https://developers.stellar.org/docs/tools/developer-tools/cli/install) (v21.5.0+)
- ✅ [Rust & Cargo](https://www.rust-lang.org/tools/install)
- ✅ [Node.js & npm](https://nodejs.org/) (v18+)
- ✅ [Noir (nargo)](https://noir-lang.org/docs/getting_started/installation/)
- ✅ [Freighter Wallet](https://www.freighter.app/) (browser extension)

## 🏃 Quick Start (Local Network)

### 1. Setup Everything

Run the setup script to prepare the frontend:

```bash
cd trap-grid-dapp-and-contracts
./setup.sh
```

This will:
- Build the position-movement circuit
- Copy artifacts to the frontend
- Install dependencies
- Create environment template

### 2. Start Local Stellar Network

In a separate terminal:

```bash
stellar network start standalone
```

Wait for the message: `✓ stellar-soroban-network is up-to-date`

### 3. Deploy Contracts

```bash
./deploy-local.sh
```

This comprehensive script will:
- ✅ Compile the position-movement circuit
- ✅ Generate the verification key  
- ✅ Build the UltraHonk verifier contract
- ✅ Build game contracts
- ✅ Deploy all contracts to local network
- ✅ Initialize contracts with correct VK
- ✅ Auto-configure frontend environment

Expected output:
```
====================================
✅ Deployment Complete!
====================================

Contract Addresses:
-------------------
Game Hub:   CXXXXXXX...
Trap Grid:  CXXXXXXX...
Verifier:   CXXXXXXX...

Addresses saved to app/.env.local
```

### 4. Start Frontend

```bash
cd app
npm run dev
```

### 5. Open the App

Navigate to http://localhost:5678

### 6. Play the Game!

#### As Defender (Player A):
1. Go to http://localhost:5678/defender
2. Connect Freighter wallet
3. Click cells to place traps (💣)
4. Click "Save Trap Grid"
5. Enter attacker's address
6. Click "Start Game"

#### As Attacker (Player B):
1. Go to http://localhost:5678/attacker
2. Connect Freighter wallet
3. Enter the session ID from defender
4. Click "Load Game"
5. Click cells to make moves
6. Submit your attack!

## 🌐 Deploy to Stellar Testnet

### 1. Create Testnet Account

```bash
stellar keys generate my-testnet-key
stellar keys fund my-testnet-key --network testnet
```

### 2. Set Environment Variable

```bash
export STELLAR_SOURCE_ACCOUNT=my-testnet-key
```

Or add to `.env` file:
```bash
echo "STELLAR_SOURCE_ACCOUNT=my-testnet-key" > .env
```

### 3. Deploy to Testnet

```bash
./deploy-testnet.sh
```

This will deploy everything to Stellar Testnet and update `app/.env.local` automatically.

### 4. Update Frontend and Test

```bash
cd app
npm run dev
```

The frontend will now connect to Stellar Testnet!

## 📝 Important Notes

### Circuit Artifact Location

The compiled circuit must be available at:
```
app/public/circuits/trap_grid_position_movement.json
```

The setup and deployment scripts handle this automatically.

### Environment Variables

After deployment, check `app/.env.local`:

```env
NEXT_PUBLIC_GAME_HUB_CONTRACT=CXXXXX...
NEXT_PUBLIC_TRAP_GRID_CONTRACT=CXXXXX...
NEXT_PUBLIC_VERIFIER_CONTRACT=CXXXXX...
NEXT_PUBLIC_NETWORK_PASSPHRASE=Standalone Network ; February 2017
NEXT_PUBLIC_RPC_URL=http://localhost:8000/soroban/rpc
```

### Testing the Circuit

To test just the circuit without deploying:

```bash
cd ../trap-grid/trap-grid-position-movement
sh circuit_test.sh
```

### Testing On-Chain Verification

To test the full verification flow on testnet:

```bash
cd ../
sh test-verification_trap-grid_trap-grid-position-movement-circuit.sh
```

## 🐛 Troubleshooting

### "Circuit artifact not found"

Run the setup script:
```bash
./setup.sh
```

### "Verifier WASM not found"

Build the verifier:
```bash
cd ../rs-soroban-ultrahonk
stellar contract build
cd -
```

### "stellar command not found"

Install Stellar CLI:
```bash
# On macOS
brew install stellar/tap/stellar-cli

# Or download from:
# https://github.com/stellar/stellar-cli/releases
```

### "nargo command not found"

Install Noir:
```bash
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
noirup
```

### Freighter Not Connecting

1. Make sure Freighter is installed
2. Check you're on the correct network (Testnet/Standalone)
3. Switch network in Freighter settings
4. Refresh the page

### Contract Deployment Fails

**For local network:**
```bash
# Restart the network
stellar network stop standalone
stellar network start standalone
```

**For testnet:**
```bash
# Check your account balance
stellar keys fund my-testnet-key --network testnet
```

## 🎯 What's Next?

After successfully deploying and testing:

1. **Generate a Proof**
   - Play as defender and attacker
   - Watch the ZK proof generation in action
   - See on-chain verification succeed! ✅

2. **Explore the Code**
   - Check out `app/src/lib/zkProof.ts` for proof generation
   - Look at `app/src/lib/poseidon.ts` for hashing
   - Review the circuit in `../trap-grid/trap-grid-position-movement/`

3. **Customize the Game**
   - Adjust grid size (update circuit and frontend)
   - Add more game mechanics
   - Implement scoring system

## 📚 Additional Resources

- 📖 [Full Documentation](./README-POSITION-MOVEMENT.md)
- 📝 [Implementation Summary](./IMPLEMENTATION_SUMMARY.md)
- 🔬 [Circuit Code](../trap-grid/trap-grid-position-movement/src/main.nr)
- 🔐 [Verifier Contract](../rs-soroban-ultrahonk/src/lib.rs)

## 🎉 Success Indicators

You'll know everything is working when:

✅ Circuit compiles without errors  
✅ Contracts deploy successfully  
✅ Frontend connects to wallet  
✅ Game starts on-chain  
✅ Moves are submitted  
✅ Proofs are generated  
✅ Proofs are verified on-chain ⭐

---

**Need help?** Check the [troubleshooting section](#-troubleshooting) or review the full documentation.

**Ready to build?** Start with `./setup.sh` and follow this guide!

Good luck and have fun! 🎲✨
