import * as StellarSdk from '@stellar/stellar-sdk';
import { CONTRACT_CONFIG } from './config';
import { GameState, Move } from '@/types';
import { signTransaction as signWithFreighter } from './utils';

export { signWithFreighter as signTransaction };

/**
 * Get Stellar Server instance
 */
export function getServer(): StellarSdk.SorobanRpc.Server {
  return new StellarSdk.SorobanRpc.Server(CONTRACT_CONFIG.rpcUrl);
}

/**
 * Load account from public key
 */
export async function loadAccount(publicKey: string): Promise<StellarSdk.Account> {
  const server = getServer();
  return await server.getAccount(publicKey);
}

/**
 * Start a new game
 */
export async function startGame(
  sessionId: number,
  defender: string,
  attacker: string,
  trapMerkleRoot: string,
  defenderPoints: number,
  attackerPoints: number,
  signerPublicKey: string
): Promise<string> {
  const server = getServer();
  const account = await loadAccount(signerPublicKey);

  const contract = new StellarSdk.Contract(CONTRACT_CONFIG.trapGridContract);

  const transaction = new StellarSdk.TransactionBuilder(account, {
    fee: StellarSdk.BASE_FEE,
    networkPassphrase: CONTRACT_CONFIG.networkPassphrase,
  })
    .addOperation(
      contract.call(
        'start_game',
        StellarSdk.nativeToScVal(sessionId, { type: 'u32' }),
        new StellarSdk.Address(defender).toScVal(),
        new StellarSdk.Address(attacker).toScVal(),
        StellarSdk.nativeToScVal(trapMerkleRoot, { type: 'bytes' }),
        StellarSdk.nativeToScVal(defenderPoints, { type: 'i128' }),
        StellarSdk.nativeToScVal(attackerPoints, { type: 'i128' })
      )
    )
    .setTimeout(30)
    .build();

  const prepared = await server.prepareTransaction(transaction);
  return prepared.toXDR();
}

/**
 * Make a move with ZK proof
 */
export async function makeMove(
  sessionId: number,
  x: number,
  y: number,
  isHit: boolean,
  proof: Uint8Array,
  publicInputs: Uint8Array,
  signerPublicKey: string
): Promise<string> {
  const server = getServer();
  const account = await loadAccount(signerPublicKey);

  const contract = new StellarSdk.Contract(CONTRACT_CONFIG.trapGridContract);

  const transaction = new StellarSdk.TransactionBuilder(account, {
    fee: StellarSdk.BASE_FEE,
    networkPassphrase: CONTRACT_CONFIG.networkPassphrase,
  })
    .addOperation(
      contract.call(
        'make_move',
        StellarSdk.nativeToScVal(sessionId, { type: 'u32' }),
        StellarSdk.nativeToScVal(x, { type: 'u32' }),
        StellarSdk.nativeToScVal(y, { type: 'u32' }),
        StellarSdk.nativeToScVal(isHit, { type: 'bool' }),
        StellarSdk.nativeToScVal(proof, { type: 'bytes' }),
        StellarSdk.nativeToScVal(publicInputs, { type: 'bytes' })
      )
    )
    .setTimeout(30)
    .build();

  const prepared = await server.prepareTransaction(transaction);
  return prepared.toXDR();
}

/**
 * Get game state
 */
export async function getGameState(sessionId: number): Promise<GameState | null> {
  try {
    const server = getServer();
    const contract = new StellarSdk.Contract(CONTRACT_CONFIG.trapGridContract);

    // Create a temporary account for read-only operation
    const sourceKeypair = StellarSdk.Keypair.random();
    const sourceAccount = new StellarSdk.Account(sourceKeypair.publicKey(), '0');

    const transaction = new StellarSdk.TransactionBuilder(sourceAccount, {
      fee: StellarSdk.BASE_FEE,
      networkPassphrase: CONTRACT_CONFIG.networkPassphrase,
    })
      .addOperation(
        contract.call('get_game', StellarSdk.nativeToScVal(sessionId, { type: 'u32' }))
      )
      .setTimeout(30)
      .build();

    const response = await server.simulateTransaction(transaction);

    if (
      StellarSdk.SorobanRpc.Api.isSimulationSuccess(response) &&
      response.result
    ) {
      const value = response.result.retval;
      // Parse the returned value into GameState
      // This is a simplified version - actual parsing depends on the contract's return type
      return parseGameState(value);
    }

    return null;
  } catch (error) {
    console.error('Error getting game state:', error);
    return null;
  }
}

/**
 * Get moves for a game
 */
export async function getMoves(sessionId: number): Promise<Move[]> {
  try {
    const server = getServer();
    const contract = new StellarSdk.Contract(CONTRACT_CONFIG.trapGridContract);

    const sourceKeypair = StellarSdk.Keypair.random();
    const sourceAccount = new StellarSdk.Account(sourceKeypair.publicKey(), '0');

    const transaction = new StellarSdk.TransactionBuilder(sourceAccount, {
      fee: StellarSdk.BASE_FEE,
      networkPassphrase: CONTRACT_CONFIG.networkPassphrase,
    })
      .addOperation(
        contract.call('get_moves', StellarSdk.nativeToScVal(sessionId, { type: 'u32' }))
      )
      .setTimeout(30)
      .build();

    const response = await server.simulateTransaction(transaction);

    if (
      StellarSdk.SorobanRpc.Api.isSimulationSuccess(response) &&
      response.result
    ) {
      const value = response.result.retval;
      return parseMoves(value);
    }

    return [];
  } catch (error) {
    console.error('Error getting moves:', error);
    return [];
  }
}

/**
 * Parse game state from ScVal
 */
function parseGameState(value: StellarSdk.xdr.ScVal): GameState | null {
  // Simplified parsing - adjust based on actual contract return type
  try {
    // This is a placeholder implementation
    // Actual implementation depends on the exact ScVal structure returned by the contract
    return {
      sessionId: 0,
      defender: '',
      attacker: '',
      defenderPoints: 0,
      attackerPoints: 0,
      trapMerkleRoot: '',
      movesMade: 0,
      hits: 0,
      misses: 0,
      gameStarted: false,
      gameEnded: false,
    };
  } catch (error) {
    console.error('Error parsing game state:', error);
    return null;
  }
}

/**
 * Parse moves from ScVal
 */
function parseMoves(value: StellarSdk.xdr.ScVal): Move[] {
  // Simplified parsing - adjust based on actual contract return type
  try {
    // This is a placeholder implementation
    return [];
  } catch (error) {
    console.error('Error parsing moves:', error);
    return [];
  }
}

/**
 * Submit signed transaction
 */
export async function submitTransaction(signedXDR: string): Promise<StellarSdk.SorobanRpc.Api.GetTransactionResponse> {
  const server = getServer();
  const transaction = StellarSdk.TransactionBuilder.fromXDR(
    signedXDR,
    CONTRACT_CONFIG.networkPassphrase
  ) as StellarSdk.Transaction;

  const response = await server.sendTransaction(transaction);

  // Poll for result
  let getResponse = await server.getTransaction(response.hash);

  while (getResponse.status === StellarSdk.SorobanRpc.Api.GetTransactionStatus.NOT_FOUND) {
    await new Promise((resolve) => setTimeout(resolve, 1000));
    getResponse = await server.getTransaction(response.hash);
  }

  return getResponse;
}
