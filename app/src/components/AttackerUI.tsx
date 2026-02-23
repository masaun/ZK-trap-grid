'use client';

import { useState, useEffect } from 'react';
import Grid from '@/components/Grid';
import WalletConnect from '@/components/WalletConnect';
import { Cell, GameState, Move } from '@/types';
import { initializeGrid } from '@/lib/utils';
import { getGameState, getMoves, makeMove, submitTransaction } from '@/lib/stellar';
import { useWallet } from 'stellar-wallet-kit';
import { CONTRACT_CONFIG } from '@/lib/config';

export default function AttackerUI() {
  const { account, signTransaction } = useWallet();
  const publicKey = account?.address;
  const [grid, setGrid] = useState<Cell[][]>(initializeGrid());
  const [sessionId, setSessionId] = useState<number>(0);
  const [gameState, setGameState] = useState<GameState | null>(null);
  const [moves, setMoves] = useState<Move[]>([]);
  const [selectedCell, setSelectedCell] = useState<{ x: number; y: number } | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<string>('');

  const handleWalletConnect = (key: string) => {
    // Wallet is now connected via context
    console.log('Wallet connected:', key);
  };

  useEffect(() => {
    if (sessionId > 0) {
      loadGameState();
    }
  }, [sessionId]);

  const loadGameState = async () => {
    if (!sessionId || sessionId <= 0 || !Number.isInteger(sessionId)) {
      setMessage('Please enter a valid session ID');
      return;
    }

    setIsLoading(true);
    setMessage('Loading game...');
    try {
      const state = await getGameState(sessionId);
      if (state) {
        setGameState(state);
        const gameMoves = await getMoves(sessionId);
        setMoves(gameMoves);
        updateGridWithMoves(gameMoves);
        setMessage('Game loaded successfully');
      } else {
        setMessage(`Game not found (Session ID: ${sessionId}). Please check the session ID or ask the defender (Player A) to start the game first.`);
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

      const signResult = await signTransaction(xdr);
      const signedXDR = signResult.signedTxXdr;
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
          <WalletConnect onConnect={handleWalletConnect} />
        </div>

        {publicKey && (
          <>
            <div className="card mb-6">
              <h2 className="text-2xl font-semibold mb-4">Join Game</h2>
              
              <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 mb-4">
                <p className="text-sm text-blue-800 dark:text-blue-200">
                  ℹ️ <strong>Note:</strong> You need the Session ID from the defender (Player A) who started the game. 
                  Make sure the defender has set their traps and started the game before you try to load it.
                </p>
              </div>
              
              <div className="flex gap-4">
                <div className="flex-1">
                  <label className="block font-medium mb-2">Session ID</label>
                  <input
                    type="number"
                    min="1"
                    step="1"
                    value={sessionId || ''}
                    onChange={(e) => {
                      const value = parseInt(e.target.value, 10);
                      setSessionId(isNaN(value) ? 0 : value);
                    }}
                    placeholder="Enter game session ID from Player A"
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
                <div className="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 border-2 border-blue-300 dark:border-blue-700 rounded-lg p-6 mb-6">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-1">🎮 Active Game Session</p>
                      <p className="text-3xl font-bold text-blue-600 dark:text-blue-400">#{gameState.sessionId}</p>
                    </div>
                    <div className="text-right">
                      <p className="text-sm text-gray-600 dark:text-gray-400">Playing against</p>
                      <p className="text-sm font-mono text-gray-800 dark:text-gray-200 truncate max-w-xs">
                        {gameState.defender ? `${gameState.defender.slice(0, 8)}...${gameState.defender.slice(-8)}` : 'Unknown'}
                      </p>
                    </div>
                  </div>
                </div>

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
