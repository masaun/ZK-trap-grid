import type { Metadata } from 'next';
import './globals.css';

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
      <body>{children}</body>
    </html>
  );
}
