// Configuration for local Stellar network
export const CONTRACT_CONFIG = {
  trapGridContract: process.env.NEXT_PUBLIC_TRAP_GRID_CONTRACT || '',
  gameHubContract: process.env.NEXT_PUBLIC_GAME_HUB_CONTRACT || '',
  verifierContract: process.env.NEXT_PUBLIC_VERIFIER_CONTRACT || '',
  networkPassphrase: process.env.NEXT_PUBLIC_NETWORK_PASSPHRASE || 'Standalone Network ; February 2017',
  rpcUrl: process.env.NEXT_PUBLIC_RPC_URL || 'http://localhost:8000/soroban/rpc',
};

export const GRID_SIZE = 8;
export const MAX_MOVES = 64;
export const MERKLE_TREE_DEPTH = 6; // log2(64) = 6
