'use client';

import { Cell } from '@/types';
import { GRID_SIZE } from '@/lib/config';
import clsx from 'clsx';

interface GridProps {
  grid: Cell[][];
  onCellClick?: (x: number, y: number) => void;
  isInteractive?: boolean;
  showTraps?: boolean;
}

export default function Grid({
  grid,
  onCellClick,
  isInteractive = false,
  showTraps = false,
}: GridProps) {
  const handleClick = (x: number, y: number) => {
    if (isInteractive && onCellClick) {
      onCellClick(x, y);
    }
  };

  return (
    <div className="flex flex-col gap-1 bg-gray-200 dark:bg-gray-700 p-4 rounded-lg">
      {Array.from({ length: GRID_SIZE }).map((_, x) => (
        <div key={x} className="flex gap-1">
          {Array.from({ length: GRID_SIZE }).map((_, y) => {
            const cell = grid[x][y];
            const showTrap = showTraps && cell.hasTrap;
            const isHit = cell.isRevealed && cell.isHit;
            const isMiss = cell.isRevealed && !cell.isHit;

            return (
              <button
                key={`${x}-${y}`}
                onClick={() => handleClick(x, y)}
                disabled={!isInteractive || cell.isRevealed}
                className={clsx('grid-cell', {
                  'grid-cell-trap': showTrap && !cell.isRevealed,
                  'grid-cell-hit': isHit,
                  'grid-cell-miss': isMiss,
                  'cursor-not-allowed': !isInteractive || cell.isRevealed,
                })}
                title={`Cell (${x}, ${y})`}
              >
                {showTrap && !cell.isRevealed && '💣'}
                {isHit && '💥'}
                {isMiss && '❌'}
              </button>
            );
          })}
        </div>
      ))}
    </div>
  );
}
