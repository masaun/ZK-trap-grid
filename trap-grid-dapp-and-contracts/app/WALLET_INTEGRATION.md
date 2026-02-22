# Stellar Wallet Kit Integration

This document describes the Stellar Wallet Kit integration in the Trap Grid dApp frontend.

## Overview

The app uses [Stellar Wallet Kit](https://developers.stellar.org/docs/tools/developer-tools/wallets#stellar-wallet-kit) to provide a unified wallet connection experience that supports multiple Stellar wallets including:

- **Freighter** - Browser extension wallet
- **Albedo** - Web-based wallet
- **xBull** - Browser extension wallet
- **Rabet** - Browser extension wallet
- **WalletConnect** - Mobile wallet connection

## Architecture

### 1. WalletContext (`src/contexts/WalletContext.tsx`)

The `WalletContext` provides a React context that manages wallet state throughout the application:

```typescript
interface WalletContextType {
  kit: StellarWalletKit | null;       // The wallet kit instance
  publicKey: string | null;            // Connected wallet address
  isConnected: boolean;                 // Connection status
  isConnecting: boolean;                // Loading state
  error: string | null;                 // Error messages
  connectWallet: () => Promise<void>;  // Open wallet modal
  disconnectWallet: () => Promise<void>; // Disconnect wallet
  signTransaction: (xdr: string) => Promise<string>; // Sign transactions
}
```

**Key Features:**
- Automatically initializes Wallet Kit on mount
- Detects network from environment config (Testnet/Standalone/Public)
- Persists connection in localStorage
- Provides transaction signing functionality

### 2. WalletConnect Component (`src/components/WalletConnect.tsx`)

A reusable React component that provides wallet connection UI:

```tsx
<WalletConnect onConnect={(publicKey) => console.log(publicKey)} />
```

**Features:**
- Shows "Connect Wallet" button when disconnected
- Displays connected address with disconnect option
- Shows loading state during connection
- Displays error messages
- Notifies parent component on connection

### 3. Layout Integration (`src/app/layout.tsx`)

The `WalletProvider` wraps the entire application:

```tsx
<WalletProvider>
  {children}
</WalletProvider>
```

### 4. Styling (`src/app/wallet-kit.css`)

Custom styles for the wallet selection modal with:
- Light/dark mode support
- Responsive design
- Smooth animations
- Accessible UI

## Usage in Components

### Example: DefenderUI Component

```tsx
import { useWallet } from '@/contexts/WalletContext';

export default function DefenderUI() {
  const { publicKey, signTransaction, isConnected } = useWallet();

  const handleStartGame = async () => {
    if (!publicKey) return;

    // Build transaction
    const xdr = await startGame(sessionId, publicKey, attacker, points, points, publicKey);
    
    // Sign with connected wallet
    const signedXDR = await signTransaction(xdr);
    
    // Submit to network
    const result = await submitTransaction(signedXDR);
  };

  return (
    <div>
      <WalletConnect onConnect={(key) => console.log('Connected:', key)} />
      {isConnected && <GameInterface />}
    </div>
  );
}
```

## Network Configuration

The wallet kit automatically selects the network based on `CONTRACT_CONFIG`:

```typescript
// In .env.local
NEXT_PUBLIC_NETWORK_PASSPHRASE=Test SDF Network ; September 2015
NEXT_PUBLIC_RPC_URL=https://soroban-testnet.stellar.org
```

Supported networks:
- **Standalone**: `Standalone Network ; February 2017`
- **Testnet**: `Test SDF Network ; September 2015`
- **Public**: `Public Global Stellar Network ; September 2015`

## Transaction Signing Flow

1. **Build Transaction**: Create unsigned transaction XDR
   ```typescript
   const xdr = await startGame(...params);
   ```

2. **Sign via Wallet**: Use context's `signTransaction`
   ```typescript
   const signedXDR = await signTransaction(xdr);
   ```

3. **Submit to Network**: Submit the signed transaction
   ```typescript
   const result = await submitTransaction(signedXDR);
   ```

## Wallet Modal

When users click "Connect Wallet", a modal appears showing:

1. **Detected Wallets**: Installed browser extensions
2. **Supported Wallets**: Other available options
3. **Download Links**: For wallets not yet installed

The modal automatically detects which wallets are available and shows installation instructions for others.

## Error Handling

The context handles various error scenarios:

- **Wallet Not Installed**: Shows in modal with download link
- **User Rejection**: Shows "User rejected the request"
- **Network Mismatch**: Alerts user to switch networks
- **Connection Timeout**: Shows timeout error after 30s

Example error handling:

```tsx
const { error, connectWallet } = useWallet();

<button onClick={connectWallet}>Connect</button>
{error && <div className="error">{error}</div>}
```

## Persistence

The wallet connection persists across page reloads:

- **Storage**: Uses `localStorage` to save public key
- **Auto-reconnect**: Checks for saved key on mount
- **Manual Disconnect**: Clears localStorage on disconnect

## Security Considerations

1. **No Private Keys**: The app never accesses private keys
2. **User Approval**: Every transaction requires user approval in wallet
3. **Network Validation**: Ensures correct network before signing
4. **XDR Validation**: Wallets validate transaction details

## Customization

### Custom Wallet Modal Styles

Edit `src/app/wallet-kit.css` to customize the modal appearance:

```css
.swk-modal-container {
  max-width: 600px; /* Wider modal */
  border-radius: 16px; /* More rounded corners */
}
```

### Custom Network Configuration

Override network in WalletContext initialization:

```typescript
const walletKit = new StellarWalletKit({
  network: WalletNetwork.TESTNET,
  selectedWalletId: 'freighter',
});
```

### Custom Wallet Options

Specify which wallets to show:

```typescript
const walletKit = new StellarWalletKit({
  network: WalletNetwork.TESTNET,
  modules: [
    new FreighterModule(),
    new AlbedoModule(),
    new xBullModule(),
  ],
});
```

## Testing

### Local Development

1. Install Freighter extension
2. Set environment to Standalone network
3. Start local Stellar network
4. Run the app: `npm run dev`
5. Connect wallet - should show Freighter

### Testnet Testing

1. Set environment to Testnet
2. Fund account via friendbot
3. Connect wallet
4. Test transactions on testnet

## Troubleshooting

### Wallet Not Detected

**Problem**: Modal shows "Not Installed" for Freighter
**Solution**: 
- Ensure Freighter is installed and enabled
- Refresh the browser
- Check browser console for errors

### Network Mismatch

**Problem**: Transaction fails with network error
**Solution**:
- Check `.env.local` has correct `NEXT_PUBLIC_NETWORK_PASSPHRASE`
- Ensure wallet is on correct network
- Switch network in wallet settings

### Connection Persists After Disconnect

**Problem**: Page reload reconnects automatically
**Solution**:
- Check localStorage is clearing properly
- Clear browser storage manually
- Use incognito mode for testing

### Transaction Signing Fails

**Problem**: `signTransaction` throws error
**Solution**:
- Check wallet is still connected
- Verify XDR is valid
- Ensure account has sufficient balance
- Check transaction fee

## API Reference

### `useWallet()` Hook

Returns wallet context with properties and methods:

```typescript
const {
  kit,              // StellarWalletKit instance
  publicKey,        // string | null
  isConnected,      // boolean
  isConnecting,     // boolean
  error,           // string | null
  connectWallet,    // () => Promise<void>
  disconnectWallet, // () => Promise<void>
  signTransaction  // (xdr: string) => Promise<string>
} = useWallet();
```

### `WalletConnect` Component

Props:

```typescript
interface WalletConnectProps {
  onConnect: (publicKey: string) => void;  // Required
  connectedKey?: string;                    // Optional, for display
}
```

## Further Reading

- [Stellar Wallet Kit Documentation](https://developers.stellar.org/docs/tools/developer-tools/wallets#stellar-wallet-kit)
- [Stellar SDK Documentation](https://stellar.github.io/js-stellar-sdk/)
- [Freighter Wallet](https://www.freighter.app/)
- [Soroban Documentation](https://developers.stellar.org/docs/smart-contracts)

## Support

For issues with:
- **Wallet Kit**: Check [Stellar Discord](https://discord.gg/stellardev)
- **This Integration**: See project README or open an issue
- **Specific Wallets**: Contact wallet support directly
