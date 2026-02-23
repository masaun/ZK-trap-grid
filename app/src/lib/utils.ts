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
