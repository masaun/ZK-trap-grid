'use client';

import { useState, useEffect } from 'react';
import Grid from '@/components/Grid';
import WalletConnect from '@/components/WalletConnect';
import { Cell, GameState } from '@/types';
import { initializeGrid } from '@/lib/utils';
import { startGame, submitTransaction, getGameState } from '@/lib/stellar';
import { useWallet } from 'stellar-wallet-kit';
import { CONTRACT_CONFIG } from '@/lib/config';

export default function DefenderUI() {
  const { account, signTransaction } = useWallet();
  const publicKey = account?.address;
  const [grid, setGrid] = useState<Cell[][]>(initializeGrid());
  // Use seconds since epoch to ensure it fits in u32 (max: 4,294,967,295)
  const [sessionId, setSessionId] = useState<number>(Math.floor(Date.now() / 1000));
  const [attackerAddress, setAttackerAddress] = useState<string>('');
  const [points, setPoints] = useState<number>(1000);
  const [isSettingTraps, setIsSettingTraps] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<string>('');
  const [gameState, setGameState] = useState<GameState | null>(null);

  const handleWalletConnect = (key: string) => {
    // Wallet is now connected via context
    console.log('Wallet connected:', key);
  };

  // Auto-populate attacker address when game state is loaded
  useEffect(() => {
    if (gameState && gameState.attacker) {
      setAttackerAddress(gameState.attacker);
    }
  }, [gameState]);

  const handleCellClick = (x: number, y: number) => {
    if (!isSettingTraps) return;

    setGrid((prevGrid) => {
      const newGrid = prevGrid.map((row) => row.map((cell) => ({ ...cell })));
      newGrid[x][y].hasTrap = !newGrid[x][y].hasTrap;
      return newGrid;
    });
  };

  const handleCommitTraps = () => {
    // Build trap values array (row-major order)
    const trapValues: number[] = [];
    for (let x = 0; x < 8; x++) {
      for (let y = 0; y < 8; y++) {
        trapValues.push(grid[x][y].hasTrap ? 1 : 0);
      }
    }

    setIsSettingTraps(false);
    setMessage('Trap grid saved locally! You can now start the game.');

    // Store trap data in local storage for proof generation later
    localStorage.setItem(
      `trap-grid-${sessionId}`,
      JSON.stringify({ trapValues })
    );
  };

  const handleStartGame = async () => {
    if (!publicKey || !attackerAddress) {
      setMessage('Please fill all fields');
      return;
    }

    setIsLoading(true);
    setMessage('Starting game...');

    try {
      // Build transaction (no trap commitment needed upfront)
      const xdr = await startGame(
        sessionId,
        publicKey, // defender
        attackerAddress, // attacker
        points,
        points,
        publicKey
      );

      // Sign with wallet
      const signResult = await signTransaction(xdr);
      const signedXDR = signResult.signedTxXdr;

      // Submit transaction
      const result = await submitTransaction(signedXDR);

      if (result.status === 'SUCCESS') {
        setMessage(`✅ Game started successfully!\n\n🎮 SESSION ID: ${sessionId}\n\nShare this Session ID with the attacker (Player B) so they can load and join the game.`);
        
        // Load game state to display attacker address
        setTimeout(async () => {
          try {
            const state = await getGameState(sessionId);
            if (state) {
              setGameState(state);
            }
          } catch (err) {
            console.error('Error loading game state:', err);
          }
        }, 2000); // Wait 2s for transaction to be indexed
      } else {
        setMessage('Game start failed: ' + result.status);
      }
    } catch (error) {
      console.error('Error starting game:', error);
      setMessage('Error: ' + (error as Error).message);
    } finally {
      setIsLoading(false);
    }
  };

  const loadCurrentGameState = async () => {
    if (!sessionId || sessionId <= 0) {
      setMessage('Please enter a valid session ID');
      return;
    }

    setIsLoading(true);
    setMessage('Loading game state...');
    try {
      const state = await getGameState(sessionId);
      if (state) {
        setGameState(state);
        setMessage('Game state loaded successfully');
      } else {
        setMessage('Game not found with this session ID');
      }
    } catch (error) {
      console.error('Error loading game state:', error);
      setMessage('Error: ' + (error as Error).message);
    } finally {
      setIsLoading(false);
    }
  };

  const trapCount = grid.flat().filter((cell) => cell.hasTrap).length;

  return (
    <div className="container mx-auto p-8">
      <div className="max-w-4xl mx-auto">
        <h1 className="text-4xl font-bold mb-2 text-center">
          Player A - Defender UI
        </h1>
        <p className="text-center text-gray-600 dark:text-gray-400 mb-6">
          Set up your trap grid and start the game
        </p>

        <div className="mb-6">
          <WalletConnect onConnect={handleWalletConnect} />
        </div>

        {publicKey && (
          <>
            {gameState && gameState.gameStarted && (
              <div className="bg-gradient-to-r from-green-50 to-blue-50 dark:from-green-900/20 dark:to-blue-900/20 border-2 border-green-300 dark:border-green-700 rounded-lg p-6 mb-6">
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-1">✅ Game Active - Session ID</p>
                      <p className="text-3xl font-bold text-green-600 dark:text-green-400">#{gameState.sessionId}</p>
                    </div>
                    <div className="px-4 py-2 bg-white dark:bg-gray-800 rounded-lg shadow">
                      <p className="text-xs text-gray-500 dark:text-gray-400">Share this with Player B</p>
                      <button
                        onClick={() => {
                          navigator.clipboard.writeText(gameState.sessionId.toString());
                          setMessage('Session ID copied to clipboard!');
                        }}
                        className="text-blue-600 dark:text-blue-400 hover:underline text-sm font-medium mt-1"
                      >
                        📋 Copy Session ID
                      </button>
                    </div>
                  </div>
                  <div className="border-t border-green-200 dark:border-green-800 pt-3">
                    <p className="text-sm font-medium text-gray-600 dark:text-gray-400 mb-1">🎯 Attacker (Player B)</p>
                    <p className="text-lg font-mono text-gray-800 dark:text-gray-200 break-all">
                      {gameState.attacker || attackerAddress}
                    </p>
                  </div>
                </div>
              </div>
            )}

            <div className="card mb-6">
              <h2 className="text-2xl font-semibold mb-4">Game Setup</h2>
              
              <div className="bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 mb-4">
                <p className="text-sm text-blue-800 dark:text-blue-200">
                  ℹ️ <strong>Instructions:</strong> After starting the game, share the Session ID below with the attacker (Player B) so they can join your game.
                </p>
              </div>
              
              <div className="space-y-4">
                <div>
                  <label className="block font-medium mb-2">Session ID</label>
                  <div className="flex gap-2">
                    <input
                      type="number"
                      min="1"
                      max="4294967295"
                      step="1"
                      value={sessionId}
                      onChange={(e) => {
                        const value = parseInt(e.target.value, 10);
                        if (!isNaN(value) && value >= 0 && value <= 4294967295) {
                          setSessionId(value);
                        }
                      }}
                      className="flex-1 px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                      disabled={!isSettingTraps}
                    />
                    {!gameState?.gameStarted && (
                      <button
                        onClick={loadCurrentGameState}
                        disabled={isLoading || sessionId <= 0}
                        className="btn btn-secondary whitespace-nowrap"
                      >
                        {isLoading ? 'Loading...' : 'Load Game'}
                      </button>
                    )}
                  </div>
                  <p className="text-xs text-gray-500 mt-1">
                    A unique identifier for this game (auto-generated)
                    {!gameState && ' • Use "Load Game" to reconnect to an existing game'}
                  </p>
                </div>

                <div>
                  <label className="block font-medium mb-2">
                    Attacker Address (Player B)
                  </label>
                  <input
                    type="text"
                    value={gameState?.attacker || attackerAddress}
                    onChange={(e) => setAttackerAddress(e.target.value)}
                    placeholder="GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
                    className="w-full px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    disabled={!isSettingTraps || (gameState && gameState.gameStarted)}
                  />
                  {gameState && gameState.attacker && (
                    <p className="text-xs text-green-600 dark:text-green-400 mt-1">
                      ✅ Auto-loaded from blockchain
                    </p>
                  )}
                </div>

                <div>
                  <label className="block font-medium mb-2">Points</label>
                  <input
                    type="number"
                    value={points}
                    onChange={(e) => setPoints(Number(e.target.value))}
                    className="w-full px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    disabled={!isSettingTraps}
                  />
                </div>
              </div>
            </div>

            <div className="card mb-6">
              <h2 className="text-2xl font-semibold mb-4">
                {isSettingTraps ? 'Set Trap Positions' : 'Your Trap Grid'}
              </h2>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-4">
                {isSettingTraps
                  ? 'Click cells to place/remove traps (💣). Use the position-movement circuit for ZK proofs.'
                  : 'Traps are stored locally. Generate proofs when attacker makes moves.'}
              </p>

              <div className="flex justify-center mb-4">
                <Grid
                  grid={grid}
                  onCellClick={handleCellClick}
                  isInteractive={isSettingTraps}
                  showTraps={true}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="text-lg">
                  <strong>Traps placed:</strong> {trapCount} / 64
                </div>

                {isSettingTraps ? (
                  <button
                    onClick={handleCommitTraps}
                    className="btn btn-primary"
                    disabled={trapCount === 0}
                  >
                    Save Trap Grid
                  </button>
                ) : (
                  <button
                    onClick={handleStartGame}
                    className="btn btn-success"
                    disabled={isLoading || !attackerAddress}
                  >
                    {isLoading ? 'Starting...' : 'Start Game'}
                  </button>
                )}
              </div>
            </div>

            {message && (
              <div className="card bg-blue-50 dark:bg-blue-900">
                <p className="text-sm">{message}</p>
              </div>
            )}

            {!isSettingTraps && (
              <div className="card bg-green-50 dark:bg-green-900">
                <h3 className="font-semibold mb-2">Next Steps:</h3>
                <p className="text-sm">
                  1. Start the game<br />
                  2. Wait for attacker to make moves<br />
                  3. Generate ZK proofs using the position-movement circuit for each move<br />
                  4. Each proof verifies the trap value at a specific position without revealing other traps
                </p>
              </div>
            )}
          </>
        )}
      </div>
    </div>
  );
}
