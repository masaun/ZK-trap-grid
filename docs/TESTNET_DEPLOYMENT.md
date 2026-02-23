# Stellar Testnet Deployment Summary

**Deployment Date:** February 22, 2026  
**Network:** Stellar Testnet  
**Deployer Account:** deployer (GDR2DF4CADDT7L764TOBMVG3VVXFUJBBA67FPLWMTJID2U3NEM4FTA53)

---

## ✅ Deployed Contracts

### 1. Game Hub Contract (Official Hackathon)
**Address:** `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG`  
**Status:** ✅ Using official hackathon contract  
**Explorer:** https://stellar.expert/explorer/testnet/contract/CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG

### 2. UltraHonk Verifier Contract
**Address:** `CDOMNA2SUMUHLJUZO7DLSFWY7JZXVYSC3ES6KT4I7SMP7IP2BCUY3TE4`  
**Status:** ✅ Deployed with trap-grid-position-movement VK  
**Explorer:** https://stellar.expert/explorer/testnet/contract/CDOMNA2SUMUHLJUZO7DLSFWY7JZXVYSC3ES6KT4I7SMP7IP2BCUY3TE4  
**Transaction:** https://stellar.expert/explorer/testnet/tx/bb27904931ceb6026c4d8ac444a17056b9c59fe632ed5f03b5929c91f19dff3b

### 3. Trap Grid Game Contract
**Address:** `CA7LA5MVBAPEFVXYLDZ75JQZLJ2ZFMSTNYGKWAQDVAKI43C5IG2REURU`  
**Status:** ✅ Deployed and initialized  
**Explorer:** https://stellar.expert/explorer/testnet/contract/CA7LA5MVBAPEFVXYLDZ75JQZLJ2ZFMSTNYGKWAQDVAKI43C5IG2REURU  
**Transaction:** https://stellar.expert/explorer/testnet/tx/bbdbbad177a649f6cb6f624f9a81b9b21c3ed09846bb190bba3d436b3c88598e

**Initialization:**
- Admin: `GDR2DF4CADDT7L764TOBMVG3VVXFUJBBA67FPLWMTJID2U3NEM4FTA53`
- Game Hub: `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG`
- Verifier: `CDOMNA2SUMUHLJUZO7DLSFWY7JZXVYSC3ES6KT4I7SMP7IP2BCUY3TE4`

---

## 🎯 Circuit Details

**Circuit:** trap-grid-position-movement  
**Location:** `../trap-grid/trap-grid-position-movement/`  
**Verification Key:** Generated and embedded in verifier contract  
**Proving System:** UltraHonk with Keccak transcript  
**Proof Size:** ~2144 bytes

---

## 🚀 Frontend Configuration

The frontend has been configured with testnet contract addresses:

**File:** `app/.env.local`

```env
NEXT_PUBLIC_GAME_HUB_CONTRACT=CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG
NEXT_PUBLIC_TRAP_GRID_CONTRACT=CA7LA5MVBAPEFVXYLDZ75JQZLJ2ZFMSTNYGKWAQDVAKI43C5IG2REURU
NEXT_PUBLIC_VERIFIER_CONTRACT=CDOMNA2SUMUHLJUZO7DLSFWY7JZXVYSC3ES6KT4I7SMP7IP2BCUY3TE4
NEXT_PUBLIC_NETWORK_PASSPHRASE=Test SDF Network ; September 2015
NEXT_PUBLIC_RPC_URL=https://soroban-testnet.stellar.org
```

**Circuit Artifact:** ✅ Copied to `app/public/circuits/trap_grid_position_movement.json`

---

## 📋 Next Steps

### 1. Start the Frontend

```bash
cd app
npm install  # if not already done
npm run dev
```

The app will be available at http://localhost:5678

### 2. Test the Game

#### As Defender (Player A):
1. Connect wallet (Freighter, Albedo, xBull)
2. Set traps on the 8×8 grid
3. Enter attacker's address
4. Click "Start Game"
   - Triggers `trap_grid.start_game()`
   - Which calls `game_hub.start_game()` (official contract)
5. Wait for attacker's moves
6. Generate ZK proofs for each move
7. Submit proofs for on-chain verification

#### As Attacker (Player B):
1. Connect wallet
2. Enter defender's session ID
3. Load game state
4. Click cells to make moves
5. View results (hit/miss) after defender provides proof

---

## ✅ Hackathon Compliance Checklist

- ✅ **Deployed on Stellar Testnet**
- ✅ **Calls start_game() on official Game Hub:** `CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG`
- ✅ **Calls end_game() on official Game Hub**
- ✅ **On-chain ZK proof verification** using UltraHonk verifier
- ✅ **Working frontend** with wallet integration
- ✅ **Circuit artifacts** ready for proof generation

---

## 🔗 Important Links

### Stellar Expert (Testnet)
- [Game Hub](https://stellar.expert/explorer/testnet/contract/CB4VZAT2U3UC6XFK3N23SKRF2NDCMP3QHJYMCHHFMZO7MRQO6DQ2EMYG)
- [Trap Grid](https://stellar.expert/explorer/testnet/contract/CA7LA5MVBAPEFVXYLDZ75JQZLJ2ZFMSTNYGKWAQDVAKI43C5IG2REURU)
- [Verifier](https://stellar.expert/explorer/testnet/contract/CDOMNA2SUMUHLJUZO7DLSFWY7JZXVYSC3ES6KT4I7SMP7IP2BCUY3TE4)

### Hackathon
- [Stellar Hacks ZK Gaming](https://dorahacks.io/hackathon/stellar-hacks-zk-gaming)
- [Submission Requirements](https://dorahacks.io/hackathon/stellar-hacks-zk-gaming/detail#submission-requirements)

---

## 📝 Contract Interaction Examples

### Start a Game
```typescript
// Defender calls
await trapGrid.start_game(
  session_id,      // e.g., Date.now()
  defender_addr,   // Stellar address
  attacker_addr,   // Stellar address
  1000,           // defender points
  1000            // attacker points
);
// → Internally calls game_hub.start_game()
```

### Make a Move & Verify
```typescript
// Attacker makes move
await trapGrid.make_move(
  session_id,
  x,              // 0-7
  y,              // 0-7
  is_hit,         // bool
  proof,          // UltraHonk proof bytes
  public_inputs   // Position, hit status
);
// → Verifier validates proof on-chain
```

### End Game
```typescript
// Called when all moves complete
await trapGrid.end_game(session_id);
// → Internally calls game_hub.end_game(session_id, player1_won)
```

---

## 🎮 Ready for Submission!

Your ZK Trap Grid game is now fully deployed on Stellar Testnet and ready for the hackathon submission. All contracts are live, integrated with the official Game Hub, and the frontend is configured to connect to testnet.

**Happy gaming! 🎲⚡**
