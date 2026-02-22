import { Cell } from '@/types';
import { GRID_SIZE } from './config';

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
