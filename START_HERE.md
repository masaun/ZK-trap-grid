# 🚀 Quick Start - ZK Trap Grid

## Fastest Way to Start

### 1. Start Stellar Network (Choose One)

**Recommended - Stellar CLI:**
```bash
stellar network container start standalone
```

**Alternative - Docker:**
```bash
docker run --rm -d -p 8000:8000 --name stellar stellar/quickstart:testing --standalone --enable-soroban-rpc
```

### 2. Deploy Contracts
```bash
cd trap-grid-dapp-and-contracts
./deploy-local.sh
```

### 3. Configure & Run Frontend
```bash
# Copy contract addresses
cp .contract-addresses.env trap-grid-frontend/.env.local

# Install & run
cd trap-grid-frontend
npm install
npm run dev
```

### 4. Open Your Browser
- Home: http://localhost:3000
- Defender: http://localhost:3000/defender
- Attacker: http://localhost:3000/attacker

## Troubleshooting

**Network won't start?**
```bash
# Check if port is free
lsof -i :8000

# Stop existing container
docker stop stellar

# Check Docker is running
docker ps
```

**Need help?**
See [QUICKSTART.md](trap-grid-dapp-and-contracts/QUICKSTART.md) for detailed instructions.

---

**Status**: Ready for deployment ✅
**Verifier**: Built (88KB WASM) ✅
**Frontend**: Complete ✅
**Docs**: [Full Documentation](trap-grid-dapp-and-contracts/)
