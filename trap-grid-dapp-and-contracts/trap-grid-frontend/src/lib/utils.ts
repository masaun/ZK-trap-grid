import { Cell, MerkleProof } from '@/types';
import { GRID_SIZE, MERKLE_TREE_DEPTH } from './config';

/**
 * Initialize an empty grid
 */
export function initializeGrid(): Cell[][] {
  const grid: Cell[][] = [];
  for (let x = 0; x < GRID_SIZE; x++) {
    grid[x] = [];
    for (let y = 0; y < GRID_SIZE; y++) {
      grid[x][y] = {
        x,
        y,
        hasTrap: false,
        isRevealed: false,
      };
    }
  }
  return grid;
}

/**
 * Calculate cell index in flattened array
 */
export function getCellIndex(x: number, y: number): number {
  return x * GRID_SIZE + y;
}

/**
 * Get coordinates from cell index
 */
export function getCoordinatesFromIndex(index: number): { x: number; y: number } {
  const x = Math.floor(index / GRID_SIZE);
  const y = index % GRID_SIZE;
  return { x, y };
}

/**
 * Simple hash function (placeholder - should use Poseidon in production)
 */
export function hashTrapValue(trapValue: number, index: number): string {
  // This is a placeholder. In production, use actual Poseidon hash
  // matching the circuit implementation
  return `hash_${trapValue}_${index}`;
}

/**
 * Build Merkle tree from trap values
 */
export function buildMerkleTree(trapValues: number[]): {
  root: string;
  tree: string[][];
} {
  if (trapValues.length !== GRID_SIZE * GRID_SIZE) {
    throw new Error('Invalid trap values length');
  }

  // Build leaves (hash each trap value with its index)
  const leaves = trapValues.map((value, index) => hashTrapValue(value, index));

  // Build tree bottom-up
  const tree: string[][] = [leaves];
  let currentLevel = leaves;

  while (currentLevel.length > 1) {
    const nextLevel: string[] = [];
    for (let i = 0; i < currentLevel.length; i += 2) {
      const left = currentLevel[i];
      const right = i + 1 < currentLevel.length ? currentLevel[i + 1] : left;
      // Simple concatenation hash (replace with actual hash in production)
      nextLevel.push(`hash(${left},${right})`);
    }
    tree.push(nextLevel);
    currentLevel = nextLevel;
  }

  return {
    root: currentLevel[0],
    tree,
  };
}

/**
 * Generate Merkle proof for a specific leaf
 */
export function generateMerkleProof(
  tree: string[][],
  leafIndex: number
): MerkleProof {
  const indices: number[] = [];
  const siblings: string[] = [];

  let currentIndex = leafIndex;

  for (let level = 0; level < tree.length - 1; level++) {
    const isRightNode = currentIndex % 2 === 1;
    const siblingIndex = isRightNode ? currentIndex - 1 : currentIndex + 1;

    indices.push(isRightNode ? 1 : 0);
    siblings.push(
      siblingIndex < tree[level].length
        ? tree[level][siblingIndex]
        : tree[level][currentIndex]
    );

    currentIndex = Math.floor(currentIndex / 2);
  }

  return { indices, siblings };
}

/**
 * Format address for display
 */
export function formatAddress(address: string): string {
  if (!address) return '';
  return `${address.slice(0, 4)}...${address.slice(-4)}`;
}

/**
 * Check if Freighter wallet is installed
 */
export async function isFreighterInstalled(): Promise<boolean> {
  return typeof window !== 'undefined' && 'freighter' in window;
}

/**
 * Get public key from Freighter
 */
export async function getPublicKey(): Promise<string> {
  if (typeof window === 'undefined' || !('freighter' in window)) {
    throw new Error('Freighter not installed');
  }

  const freighter = (window as any).freighter;
  const publicKey = await freighter.getPublicKey();
  return publicKey;
}

/**
 * Sign transaction with Freighter
 */
export async function signTransaction(xdr: string, network: string): Promise<string> {
  if (typeof window === 'undefined' || !('freighter' in window)) {
    throw new Error('Freighter not installed');
  }

  const freighter = (window as any).freighter;
  const signedXDR = await freighter.signTransaction(xdr, {
    network,
    accountToSign: await getPublicKey(),
  });
  return signedXDR;
}

/**
 * Request network change in Freighter
 */
export async function setNetwork(network: string): Promise<void> {
  if (typeof window === 'undefined' || !('freighter' in window)) {
    throw new Error('Freighter not installed');
  }

  const freighter = (window as any).freighter;
  await freighter.setNetwork(network);
}
