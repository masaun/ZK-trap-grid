'use client';

import { useState } from 'react';
import Grid from '@/components/Grid';
import WalletConnect from '@/components/WalletConnect';
import { Cell } from '@/types';
import { initializeGrid } from '@/lib/utils';
import { startGame, submitTransaction } from '@/lib/stellar';
import { useWallet } from 'stellar-wallet-kit';
import { CONTRACT_CONFIG } from '@/lib/config';

export default function DefenderUI() {
  const { account, signTransaction } = useWallet();
  const publicKey = account?.address;
  const [grid, setGrid] = useState<Cell[][]>(initializeGrid());
  const [sessionId, setSessionId] = useState<number>(Date.now());
  const [attackerAddress, setAttackerAddress] = useState<string>('');
  const [points, setPoints] = useState<number>(1000);
  const [isSettingTraps, setIsSettingTraps] = useState(true);
  const [isLoading, setIsLoading] = useState(false);
  const [message, setMessage] = useState<string>('');

  const handleWalletConnect = (key: string) => {
    // Wallet is now connected via context
    console.log('Wallet connected:', key);
  };

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
        setMessage('Game started successfully! Session ID: ' + sessionId);
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
            <div className="card mb-6">
              <h2 className="text-2xl font-semibold mb-4">Game Setup</h2>
              
              <div className="space-y-4">
                <div>
                  <label className="block font-medium mb-2">Session ID</label>
                  <input
                    type="number"
                    value={sessionId}
                    onChange={(e) => setSessionId(Number(e.target.value))}
                    className="w-full px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    disabled={!isSettingTraps}
                  />
                </div>

                <div>
                  <label className="block font-medium mb-2">
                    Attacker Address (Player B)
                  </label>
                  <input
                    type="text"
                    value={attackerAddress}
                    onChange={(e) => setAttackerAddress(e.target.value)}
                    placeholder="GXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
                    className="w-full px-4 py-2 border rounded-lg dark:bg-gray-700 dark:border-gray-600"
                    disabled={!isSettingTraps}
                  />
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
