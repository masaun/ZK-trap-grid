'use client';

import { ReactNode } from 'react';
import { WalletProvider, NetworkType } from 'stellar-wallet-kit';
import { CONTRACT_CONFIG } from '@/lib/config';

interface WalletProviderWrapperProps {
  children: ReactNode;
}

// Determine network based on config
function getNetwork(): NetworkType {
  if (CONTRACT_CONFIG.networkPassphrase.includes('Standalone')) {
    return NetworkType.STANDALONE;
  } else if (CONTRACT_CONFIG.networkPassphrase.includes('Test')) {
    return NetworkType.TESTNET;
  } else {
    return NetworkType.PUBLIC;
  }
}

export function WalletProviderWrapper({ children }: WalletProviderWrapperProps) {
  return (
    <WalletProvider
      config={{
        network: getNetwork(),
        autoConnect: true,
      }}
    >
      {children}
    </WalletProvider>
  );
}
