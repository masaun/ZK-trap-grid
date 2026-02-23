import * as StellarSdk from '@stellar/stellar-sdk';
import {
  Contract,
  TransactionBuilder,
  BASE_FEE,
  nativeToScVal,
  scValToNative,
  Address,
  Account,
  Keypair,
  xdr,
  Transaction,
  rpc
} from '@stellar/stellar-sdk';
import { CONTRACT_CONFIG } from './config';
import { GameState, Move } from '@/types';

/**
 * Get Stellar Server instance
 */
export function getServer(): rpc.Server {
  return new rpc.Server(CONTRACT_CONFIG.rpcUrl);
}

/**
 * Load account from public key
 */
export async function loadAccount(publicKey: string): Promise<Account> {
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
  defenderPoints: number,
  attackerPoints: number,
  signerPublicKey: string
): Promise<string> {
  // Validate sessionId is a valid u32
  if (!Number.isInteger(sessionId) || sessionId < 0 || sessionId > 4294967295) {
    throw new Error(`Invalid session ID: ${sessionId}. Must be an integer between 0 and 4294967295.`);
  }

  const server = getServer();
  const account = await loadAccount(signerPublicKey);

  const contract = new Contract(CONTRACT_CONFIG.trapGridContract);

  const transaction = new TransactionBuilder(account, {
    fee: BASE_FEE,
    networkPassphrase: CONTRACT_CONFIG.networkPassphrase,
  })
    .addOperation(
      contract.call(
        'start_game',
        nativeToScVal(sessionId, { type: 'u32' }),
        new Address(defender).toScVal(),
        new Address(attacker).toScVal(),
        nativeToScVal(defenderPoints, { type: 'i128' }),
        nativeToScVal(attackerPoints, { type: 'i128' })
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
  // Validate sessionId is a valid u32
  if (!Number.isInteger(sessionId) || sessionId < 0 || sessionId > 4294967295) {
    throw new Error(`Invalid session ID: ${sessionId}. Must be an integer between 0 and 4294967295.`);
  }
  // Validate coordinates are valid u32
  if (!Number.isInteger(x) || x < 0 || x > 4294967295) {
    throw new Error(`Invalid x coordinate: ${x}. Must be an integer between 0 and 4294967295.`);
  }
  if (!Number.isInteger(y) || y < 0 || y > 4294967295) {
    throw new Error(`Invalid y coordinate: ${y}. Must be an integer between 0 and 4294967295.`);
  }

  const server = getServer();
  const account = await loadAccount(signerPublicKey);

  const contract = new Contract(CONTRACT_CONFIG.trapGridContract);

  const transaction = new TransactionBuilder(account, {
    fee: BASE_FEE,
    networkPassphrase: CONTRACT_CONFIG.networkPassphrase,
  })
    .addOperation(
      contract.call(
        'make_move',
        nativeToScVal(sessionId, { type: 'u32' }),
        nativeToScVal(x, { type: 'u32' }),
        nativeToScVal(y, { type: 'u32' }),
        nativeToScVal(isHit, { type: 'bool' }),
        nativeToScVal(proof, { type: 'bytes' }),
        nativeToScVal(publicInputs, { type: 'bytes' })
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
    // Validate sessionId is a valid u32
    if (!Number.isInteger(sessionId) || sessionId < 0 || sessionId > 4294967295) {
      console.error('Invalid session ID:', sessionId);
      return null;
    }

    const server = getServer();
    const contract = new Contract(CONTRACT_CONFIG.trapGridContract);

    // Create a temporary account for read-only operation
    const sourceKeypair = Keypair.random();
    const sourceAccount = new Account(sourceKeypair.publicKey(), '0');

    const transaction = new TransactionBuilder(sourceAccount, {
      fee: BASE_FEE,
      networkPassphrase: CONTRACT_CONFIG.networkPassphrase,
    })
      .addOperation(
        contract.call('get_game', nativeToScVal(sessionId, { type: 'u32' }))
      )
      .setTimeout(30)
      .build();

    const response = await server.simulateTransaction(transaction);

    console.log('getGameState response:', response);

    // Check for simulation errors (using type assertion as error field is not in types but exists at runtime)
    // @ts-ignore - error property exists at runtime but not in types
    if (response.error) {
      // @ts-ignore
      console.error('Simulation error:', response.error);
      
      // Parse contract error - Error(Contract, #1) is GameNotFound
      // @ts-ignore
      if (response.error.includes('Error(Contract, #1)')) {
        console.log('Game not found (Error #1)');
        return null;
      }
      
      // @ts-ignore
      throw new Error(`Contract error: ${response.error}`);
    }

    if (
      response &&
      'result' in response &&
      response.result
    ) {
      const value = response.result.retval;
      console.log('getGameState retval:', value);
      // Parse the returned value into GameState
      // This is a simplified version - actual parsing depends on the contract's return type
      return parseGameState(value, sessionId);
    }

    console.log('getGameState: No result in response');
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
    // Validate sessionId is a valid u32
    if (!Number.isInteger(sessionId) || sessionId < 0 || sessionId > 4294967295) {
      console.error('Invalid session ID:', sessionId);
      return [];
    }

    const server = getServer();
    const contract = new Contract(CONTRACT_CONFIG.trapGridContract);

    const sourceKeypair = Keypair.random();
    const sourceAccount = new Account(sourceKeypair.publicKey(), '0');

    const transaction = new TransactionBuilder(sourceAccount, {
      fee: BASE_FEE,
      networkPassphrase: CONTRACT_CONFIG.networkPassphrase,
    })
      .addOperation(
        contract.call('get_moves', nativeToScVal(sessionId, { type: 'u32' }))
      )
      .setTimeout(30)
      .build();

    const response = await server.simulateTransaction(transaction);

    console.log('getMoves response:', response);

    if (
      response &&
      'result' in response &&
      response.result
    ) {
      const value = response.result.retval;
      console.log('getMoves retval:', value);
      return parseMoves(value);
    }

    console.log('getMoves: No result in response');
    return [];
  } catch (error) {
    console.error('Error getting moves:', error);
    return [];
  }
}

/**
 * Parse game state from ScVal
 */
function parseGameState(value: xdr.ScVal, sessionId: number): GameState | null {
  try {
    console.log('parseGameState value:', value);
    
    // Convert ScVal to native JavaScript object
    const nativeValue = scValToNative(value);
    console.log('parseGameState nativeValue:', nativeValue);

    // The contract returns Result<Game, Error>
    // Check if it's an Ok result
    if (!nativeValue || typeof nativeValue !== 'object') {
      console.log('parseGameState: Invalid native value type');
      return null;
    }

    // Soroban Result is typically a variant with "Ok" or "Err" 
    // But scValToNative may have already unpacked it
    // The Game struct should have these fields based on the contract
    const game: any = nativeValue;
    
    // Parse the game data
    return {
      sessionId: sessionId,
      defender: game.defender || '',
      attacker: game.attacker || '',
      defenderPoints: Number(game.defender_points || 0),
      attackerPoints: Number(game.attacker_points || 0),
      movesMade: Number(game.moves_made || 0),
      hits: Number(game.hits || 0),
      misses: Number(game.misses || 0),
      gameStarted: Boolean(game.game_started),
      gameEnded: Boolean(game.game_ended),
      winner: game.winner || undefined,
    };
  } catch (error) {
    console.error('Error parsing game state:', error);
    return null;
  }
}

/**
 * Parse moves from ScVal
 */
function parseMoves(value: xdr.ScVal): Move[] {
  try {
    console.log('parseMoves value:', value);
    
    // Convert ScVal to native JavaScript object
    const nativeValue = scValToNative(value);
    console.log('parseMoves nativeValue:', nativeValue);

    // The contract returns Vec<Move>
    if (!Array.isArray(nativeValue)) {
      console.log('parseMoves: Not an array');
      return [];
    }

    // Parse each move
    return nativeValue.map((move: any) => ({
      x: Number(move.x || 0),
      y: Number(move.y || 0),
      isHit: Boolean(move.is_hit),
      verified: Boolean(move.verified),
    }));
  } catch (error) {
    console.error('Error parsing moves:', error);
    return [];
  }
}

/**
 * Submit signed transaction
 */
export async function submitTransaction(signedXDR: string): Promise<any> {
  const server = getServer();
  const transaction = TransactionBuilder.fromXDR(
    signedXDR,
    CONTRACT_CONFIG.networkPassphrase
  ) as Transaction;

  const response = await server.sendTransaction(transaction);

  // Poll for result
  let getResponse = await server.getTransaction(response.hash);

  while (getResponse.status === 'NOT_FOUND') {
    await new Promise((resolve) => setTimeout(resolve, 1000));
    getResponse = await server.getTransaction(response.hash);
  }

  return getResponse;
}
