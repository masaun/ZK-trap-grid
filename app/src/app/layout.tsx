import type { Metadata } from 'next';
import './globals.css';
import './wallet-kit.css';
import { WalletProviderWrapper } from '@/providers/WalletProviderWrapper';

export const metadata: Metadata = {
  title: 'ZK Trap Grid Game',
  description: 'Zero-Knowledge Proof Trap Grid Game on Stellar',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <WalletProviderWrapper>
          {children}
        </WalletProviderWrapper>
      </body>
    </html>
  );
}
