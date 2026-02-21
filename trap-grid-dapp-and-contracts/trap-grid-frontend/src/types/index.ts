export interface GameState {
  sessionId: number;
  defender: string;
  attacker: string;
  defenderPoints: number;
  attackerPoints: number;
  trapMerkleRoot: string;
  movesMade: number;
  hits: number;
  misses: number;
  gameStarted: boolean;
  gameEnded: boolean;
  winner?: string;
}

export interface Move {
  x: number;
  y: number;
  isHit: boolean;
  verified: boolean;
}

export interface Cell {
  x: number;
  y: number;
  hasTrap: boolean;
  isRevealed: boolean;
  isHit?: boolean;
}

export interface MerkleProof {
  indices: number[];
  siblings: string[];
}

export interface ZKProofData {
  proof: Uint8Array;
  publicInputs: Uint8Array;
}

export type PlayerRole = 'defender' | 'attacker';

export interface ContractConfig {
  trapGridContract: string;
  gameHubContract: string;
  verifierContract: string;
  networkPassphrase: string;
  rpcUrl: string;
}
