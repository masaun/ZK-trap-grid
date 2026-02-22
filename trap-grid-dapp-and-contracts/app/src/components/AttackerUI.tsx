'use client';

import { useState, useEffect } from 'react';
import Grid from '@/components/Grid';
import WalletConnect from '@/components/WalletConnect';
import { Cell, GameState, Move } from '@/types';
import { initializeGrid } from '@/lib/utils';
import { getGameState, getMoves, makeMove, submitTransaction } from '@/lib/stellar';
import { signTransaction } from '@/lib/utils';
import { CONTRACT_CONFIG } from '@/lib/config';

export default function AttackerUI() {
  const [publicKey, setPublicKey] = useState<string>('');
  const [grid, setGrid] = useState<Cell[][]>(initializeGrid());
  const [sessionId, setSessionId] = useState<number>(0);
  const [gameState, setGameState] = useState<GameState | null>(null);
  const [moves, setMoves] = useState<Move[]>([]);
  const [selectedCell, setSelectedCell] = useState<{ x: number; y: number } | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<string>('');

  useEffect(() => {
    if (sessionId > 0) {
      loadGameState();
    }
  }, [sessionId]);

  const loadGameState = async () => {
    setIsLoading(true);
    try {
      const state = await getGameState(sessionId);
      if (state) {
        setGameState(state);
        const gameMoves = await getMoves(sessionId);
        setMoves(gameMoves);
        updateGridWithMoves(gameMoves);
        setMessage('Game loaded successfully');
      } else {
        setMessage('Game not found');
      }
    } catch (error) {
      console.error('Error loading game:', error);
      setMessage('Error loading game: ' + (error as Error).message);
    } finally {
      setIsLoading(false);
    }
  };

  const updateGridWithMoves = (gameMoves: Move[]) => {
    setGrid((prevGrid) => {
      const newGrid = prevGrid.map((row) => row.map((cell) => ({ ...cell })));
      gameMoves.forEach((move) => {
        newGrid[move.x][move.y].isRevealed = true;
        newGrid[move.x][move.y].isHit = move.isHit;
      });
      return newGrid;
    });
  };

  const handleCellClick = (x: number, y: number) => {
    if (!gameState || gameState.gameEnded || grid[x][y].isRevealed) {
      return;
    }
    setSelectedCell({ x, y });
  };

  const handleMakeMove = async () => {
    if (!selectedCell || !publicKey || !gameState) {
      setMessage('Please select a cell and connect wallet');
      return;
    }

    setIsLoading(true);
    setMessage('Making move...');

    try {
      const { x, y } = selectedCell;

      // In a real implementation, this would:
      // 1. Wait for defender to provide the ZK proof
      // 2. Verify the proof parameters
      // Here we're using placeholder values

      const dummyProof = new Uint8Array([0]); // Placeholder
      const dummyPublicInputs = new Uint8Array([0]); // Placeholder

      // Note: In reality, the defender provides the proof after seeing the move
      // This is a simplified version for demonstration

      const xdr = await makeMove(
        sessionId,
        x,
        y,
        false, // isHit - will be determined by defender's proof
        dummyProof,
        dummyPublicInputs,
        publicKey
      );

      const signedXDR = await signTransaction(xdr, CONTRACT_CONFIG.networkPassphrase);
      const result = await submitTransaction(signedXDR);

      if (result.status === 'SUCCESS') {
        setMessage('Move submitted! Waiting for defender response...');
        // Reload game state
        await loadGameState();
        setSelectedCell(null);
      } else {
        setMessage('Move failed: ' + result.status);
      }
    } catch (error) {
      console.error('Error making move:', error);
      setMessage('Error: ' + (error as Error).message);
    } finally {
      setIsLoading(false);
    }
  };

  const hits = moves.filter((m) => m.isHit).length;
  const misses = moves.filter((m) => !m.isHit).length;

  return (
    <div className="container mx-auto p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold mb-2 text-center">
          Player B - Attacker UI
        </h1>
        <p className="text-center text-gray-600 dark:text-gray-400 mb-6">
          Make moves to discover hidden traps
        </p>

        <div className="mb-6">
          <WalletConnect onConnect={setPublicKey} connectedKey={publicKey} />
        </div>

        {publicKey && (
          <>
            <div className="card mb-6">
              <h2 className="text-2xl font-semibold mb-4">Join Game</h2>
              
              <div className="flex gap-4">
                <div className="flex-1">
                  <label className="block font-medium mb-2">Session ID</label>
                  <input
                    type="number"
                    value={sessionId || ''}
                    onChange={(e) => setSessionId(Number(e.target.value))}
                    placeholder="Enter game session ID"
                    className="w-full px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                  />
                </div>
                <div className="flex items-end">
                  <button
                    onClick={loadGameState}
                    disabled={isLoading || sessionId === 0}
                    className="btn btn-primary"
                  >
                    {isLoading ? 'Loading...' : 'Load Game'}
                  </button>
                </div>
              </div>
            </div>

            {gameState && (
              <>
                <div className="card mb-6">
                  <h2 className="text-2xl font-semibold mb-4">Game Status</h2>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <div className="text-sm text-gray-600 dark:text-gray-400">
                        Moves Made
                      </div>
                      <div className="text-2xl font-bold">
                        {gameState.movesMade} / 64
                      </div>
                    </div>
                    <div>
                      <div className="text-sm text-gray-600 dark:text-gray-400">
                        Hits / Misses
                      </div>
                      <div className="text-2xl font-bold">
                        <span className="text-red-500">{hits}</span> /{' '}
                        <span className="text-blue-500">{misses}</span>
                      </div>
                    </div>
                    <div>
                      <div className="text-sm text-gray-600 dark:text-gray-400">
                        Game Status
                      </div>
                      <div className="text-lg font-semibold">
                        {gameState.gameEnded ? (
                          <span className="text-yellow-500">Ended</span>
                        ) : (
                          <span className="text-green-500">Active</span>
                        )}
                      </div>
                    </div>
                    {gameState.winner && (
                      <div>
                        <div className="text-sm text-gray-600 dark:text-gray-400">
                          Winner
                        </div>
                        <div className="text-lg font-semibold">
                          {gameState.winner === publicKey ? 'You!' : 'Defender'}
                        </div>
                      </div>
                    )}
                  </div>
                </div>

                <div className="card mb-6">
                  <h2 className="text-2xl font-semibold mb-4">Attack Grid</h2>
                  <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                    Click a cell to select your target. Unknown cells are gray,
                    hits are red (💥), misses are blue (❌).
                  </p>

                  <div className="flex justify-center mb-4">
                    <Grid
                      grid={grid}
                      onCellClick={handleCellClick}
                      isInteractive={!gameState.gameEnded}
                      showTraps={false}
                    />
                  </div>

                  {selectedCell && (
                    <div className="flex items-center justify-between bg-yellow-50 dark:bg-yellow-900 p-4 rounded-lg">
                      <div>
                        <strong>Selected Target:</strong> ({selectedCell.x},{' '}
                        {selectedCell.y})
                      </div>
                      <div className="flex gap-2">
                        <button
                          onClick={() => setSelectedCell(null)}
                          className="btn bg-gray-500 text-white"
                        >
                          Cancel
                        </button>
                        <button
                          onClick={handleMakeMove}
                          disabled={isLoading}
                          className="btn btn-danger"
                        >
                          {isLoading ? 'Attacking...' : 'Launch Attack'}
                        </button>
                      </div>
                    </div>
                  )}
                </div>

                {message && (
                  <div className="card bg-blue-50 dark:bg-blue-900">
                    <p className="text-sm">{message}</p>
                  </div>
                )}

                <div className="card">
                  <h3 className="text-xl font-semibold mb-3">Move History</h3>
                  <div className="max-h-60 overflow-y-auto">
                    {moves.length === 0 ? (
                      <p className="text-gray-500 text-sm">No moves yet</p>
                    ) : (
                      <div className="space-y-2">
                        {moves.map((move, idx) => (
                          <div
                            key={idx}
                            className="flex items-center gap-3 text-sm border-b border-gray-200 dark:border-gray-700 pb-2"
                          >
                            <span className="font-mono">
                              ({move.x}, {move.y})
                            </span>
                            <span>→</span>
                            <span
                              className={
                                move.isHit ? 'text-red-500' : 'text-blue-500'
                              }
                            >
                              {move.isHit ? '💥 HIT' : '❌ MISS'}
                            </span>
                            {move.verified && (
                              <span className="text-green-500 text-xs">✓ Verified</span>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              </>
            )}
          </>
        )}
      </div>
    </div>
  );
}
