'use client';

import { useState, useEffect } from 'react';
import { getPublicKey, isFreighterInstalled } from '@/lib/utils';
import { formatAddress } from '@/lib/utils';

interface WalletConnectProps {
  onConnect: (publicKey: string) => void;
  connectedKey?: string;
}

export default function WalletConnect({ onConnect, connectedKey }: WalletConnectProps) {
  const [isInstalled, setIsInstalled] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    checkFreighter();
  }, []);

  const checkFreighter = async () => {
    const installed = await isFreighterInstalled();
    setIsInstalled(installed);
  };

  const handleConnect = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const publicKey = await getPublicKey();
      onConnect(publicKey);
    } catch (err) {
      setError('Failed to connect wallet');
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  if (!isInstalled) {
    return (
      <div className="card text-center">
        <p className="text-red-500 mb-4">Freighter wallet not detected</p>
        <a
          href="https://www.freighter.app/"
          target="_blank"
          rel="noopener noreferrer"
          className="btn btn-primary"
        >
          Install Freighter
        </a>
      </div>
    );
  }

  if (connectedKey) {
    return (
      <div className="flex items-center gap-2 bg-green-100 dark:bg-green-900 px-4 py-2 rounded-lg">
        <span className="text-green-800 dark:text-green-200">🟢 Connected:</span>
        <code className="text-sm">{formatAddress(connectedKey)}</code>
      </div>
    );
  }

  return (
    <div>
      <button
        onClick={handleConnect}
        disabled={isLoading}
        className="btn btn-primary"
      >
        {isLoading ? 'Connecting...' : 'Connect Wallet'}
      </button>
      {error && <p className="text-red-500 text-sm mt-2">{error}</p>}
    </div>
  );
}
