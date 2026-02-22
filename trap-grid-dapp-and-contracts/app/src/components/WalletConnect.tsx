'use client';

import React from 'react';
import { useWallet, ConnectButton } from 'stellar-wallet-kit';
import { formatAddress } from '@/lib/utils';

interface WalletConnectProps {
  onConnect: (publicKey: string) => void;
  connectedKey?: string;
}

export default function WalletConnect({ onConnect }: WalletConnectProps) {
  const { account, isConnected, disconnect } = useWallet();

  // Notify parent component when wallet connects
  React.useEffect(() => {
    if (account?.address && isConnected) {
      onConnect(account.address);
    }
  }, [account, isConnected, onConnect]);

  if (isConnected && account) {
    return (
      <div className="flex items-center gap-4 bg-green-100 dark:bg-green-900 px-4 py-3 rounded-lg">
        <div className="flex items-center gap-2 flex-1">
          <span className="text-green-800 dark:text-green-200">🟢 Connected:</span>
          <code className="text-sm font-mono">{formatAddress(account.address)}</code>
        </div>
        <button
          onClick={disconnect}
          className="btn bg-red-500 hover:bg-red-600 text-white text-sm py-1 px-3"
        >
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <div>
      <ConnectButton
        label="Connect Wallet"
        className="btn btn-primary"
        onConnect={() => {
          // Will be handled by the useEffect above
        }}
      />
      <p className="text-xs text-gray-600 dark:text-gray-400 mt-2">
        Supports Freighter, Albedo, xBull, and other Stellar wallets
      </p>
    </div>
  );
}


