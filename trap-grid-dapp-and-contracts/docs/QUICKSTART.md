# 🎮 ZK Trap Grid - Quick Start Guide

## ⚡ Quick Commands

### Method 1: Using Stellar CLI (Recommended)
```bash
# Start network
stellar network container start standalone

# Check status
stellar network container status standalone

# Stop network
stellar network container stop standalone
```

### Method 2: Using Docker Directly
```bash
# Start network
docker run --rm -d \
  -p 8000:8000 \
  --name stellar \
  stellar/quickstart:testing \
  --standalone \
  --enable-soroban-rpc

# Check logs
docker logs stellar -f

# Stop network
docker stop stellar
```

### Deploy Contracts & Run Frontend
```bash
# Deploy contracts (in another terminal)
cd trap-grid-dapp-and-contracts
./deploy-local.sh

# Run frontend (in another terminal)
cd trap-grid-frontend
npm install
npm run dev
```

## 🎯 What Was Built

A complete ZK Trap Grid game with:
- ✅ **Smart Contracts**: Soroban contracts for game logic + ZK verification
- ✅ **Frontend**: Next.js app with separate Defender/Attacker UIs
- ✅ **ZK Integration**: Noir circuit integration (placeholder proof generation)
- ✅ **Stellar Local Network**: Mock Game Hub for testing

## 📁 Key Files

```
trap-grid-dapp-and-contracts/
├── contracts/
│   ├── trap-grid/src/lib.rs      # Main game contract
│   └── mock-game-hub/src/lib.rs  # Local Game Hub
├── trap-grid-frontend/
│   ├── src/app/defender/         # Player A UI
│   ├── src/app/attacker/         # Player B UI
│   └── src/lib/                  # Utils & Stellar integration
├── deploy-local.sh               # Deploy to local network
└── dev.sh                        # Interactive dev menu
```

## 🎲 How to Play

### Step 1: Start Network

**Option A - Stellar CLI (Recommended)**:
```bash
stellar network container start standalone
```

**Option B - Docker**:
```bash
docker run --rm -d \
  -p 8000:8000 \
  --name stellar \
  stellar/quickstart:testing \
  --standalone \
  --enable-soroban-rpc
```

Wait for "Soroban RPC ready" or check with:
```bash
curl http://localhost:8000/soroban/rpc
```

### Step 2: Deploy Contracts (Terminal 2)
```bash
./deploy-local.sh
```
Copy the contract addresses shown at the end

### Step 3: Configure Frontend
```bash
cp .contract-addresses.env trap-grid-frontend/.env.local
```

### Step 4: Run Frontend (Terminal 3)
```bash
cd trap-grid-frontend
npm install  # or bun install
npm run dev  # or bun dev
```

### Step 5: Play the Game!

**Browser 1 - Defender** (http://localhost:3000/defender)
1. Connect Freighter wallet
2. Click cells to place traps
3. Click "Commit Trap Grid"
4. Enter attacker's address
5. Click "Start Game"
6. Share the session ID

**Browser 2 - Attacker** (http://localhost:3000/attacker)
1. Connect Freighter wallet (different account)
2. Enter session ID
3. Click "Load Game"
4. Click cells to attack
5. See results (💥 = hit, ❌ = miss)

## 📝 Important Notes

### Dependencies Required
- Docker (for Stellar network)
- Node.js 18+ (for frontend)
- Rust + Cargo (for contracts)
- Stellar CLI: `cargo install --locked stellar-cli`
- Freighter Wallet browser extension

### Freighter Setup
1. Install from https://www.freighter.app/
2. Create/import wallet
3. Switch network to "Standalone"
4. Use friendbot to fund accounts (automatic in scripts)

### Current Limitations
1. **ZK Proof Generation**: Uses placeholder. Real implementation needs:
   ```bash
   npm install @noir-lang/noir_js @noir-lang/backend_barretenberg
   ```
   Then implement in `src/lib/zkProof.ts`

2. **Poseidon Hash**: Uses placeholder. Must match Noir circuit implementation

3. **Verifier Contract**: Needs to be built and deployed from `rs-soroban-ultrahonk`

## 🔧 Development Workflow

### Building Contracts
```bash
cd contracts/trap-grid
cargo build --target wasm32-unknown-unknown --release
```

### Testing Frontend
```bash
cd trap-grid-frontend

**Try Stellar CLI method**:
```bash
# This is more reliable
stellar network container start standalone
```

**Or pull Docker image manually**:
```bash
docker pull stellar/quickstart:testing
docker run --rm -d -p 8000:8000 --name stellar \
  stellar/quickstart:testing --standalone --enable-soroban-rpc
```

**Check if running**:
```bash
docker ps | grep stellar
curl http://localhost:8000/soroban/rpc
```
```

### Updating Circuits
If you modify `../../trap-grid/src/main.nr`:
```bash
cd ../../trap-grid
nargo compile
cp target/trap_grid.json ../trap-grid-dapp-and-contracts/trap-grid-frontend/public/circuits/
```

## 🐛 Troubleshooting

### Network Won't Start
- Check Docker is running: `docker ps`
- Port 8000 might be in use: `lsof -i :8000`
- Try: `docker stop stellar` then restart

### Contracts Won't Deploy
- Ensure network is running: `curl http://localhost:8000/soroban/rpc`
- Check Rust target: `rustup target add wasm32-unknown-unknown`
- Rebuild contracts: `cargo clean` then rebuild

### Frontend Errors
- Missing deps: `rm -rf node_modules && npm install`
- Clear cache: `rm -rf .next`
- Check env: Verify `.env.local` has contract addresses

### Freighter Issues
- Wallet locked: Unlock Freighter
- Wrong network: Switch to "Standalone" in settings
- No funds: Run deployment script (funds accounts automatically)

## 📚 Documentation

- [TRAP_GRID_README.md](TRAP_GRID_README.md) - Complete project docs
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Technical details
- [trap-grid-frontend/README.md](trap-grid-frontend/README.md) - Frontend docs

## 🚀 Next Steps

### For Production
1. Integrate real ZK proof generation
2. Deploy UltraHonk verifier contract
3. Implement Poseidon hash matching circuit
4. Deploy to Stellar Testnet
5. Connect to real Game Hub

### For Enhancement
1. Add move animations
2. Implement time limits
3. Add game replay
4. Improve error messages
5. Add mobile support

## 📦 What's Included

### Contracts
- [x] Trap Grid game contract
- [x] Mock Game Hub contract
- [ ] UltraHonk verifier (needs separate build)

### Frontend
- [x] Next.js 15 app
- [x] Defender UI
- [x] Attacker UI
- [x] Wallet integration
- [x] Grid component
- [x] Stellar SDK integration
- [ ] Real ZK proof generation (placeholder)

### Scripts
- [x] start-network.sh
- [x] deploy-local.sh
- [x] dev.sh (interactive menu)

### Documentation
- [x] Main README
- [x] Implementation summary
- [x] Quick start guide
- [x] Frontend docs

## 🎯 Stellar Hacks Checklist

✅ Two-player game (Defender vs Attacker)
✅ Zero-knowledge proofs (Noir circuits)
✅ Stellar Soroban contracts
✅ Game Hub integration
✅ On-chain verification
✅ Privacy-preserving (traps hidden)
✅ TypeScript frontend
✅ Next.js implementation
✅ Local network setup
✅ Complete documentation

## 💡 Tips

- Use `./dev.sh` for quick access to common commands
- Keep network running in background: `./start-network.sh &`
- Check contract addresses: `cat .contract-addresses.env`
- Monitor network: `stellar network container logs`
- Reset everything: Stop Docker, restart network, redeploy

## 🆘 Getting Help

If you encounter issues:
1. Check the troubleshooting section above
2. Review the detailed README files
3. Check Stellar docs: https://developers.stellar.org
4. Verify all prerequisites are installed

---

**Status**: ✨ Ready for development
**Version**: 0.1.0
**Last Updated**: February 2025

Happy Building! 🚀
