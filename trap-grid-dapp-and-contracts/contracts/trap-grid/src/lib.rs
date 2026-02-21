#![no_std]

//! # ZK Trap Grid Game
//!
//! A two-player zero-knowledge proof game where:
//! - Player A (Defender) sets up a hidden trap grid
//! - Player B (Attacker) makes moves to discover traps
//! - Player A proves hit/miss results using ZK proofs without revealing trap positions
//!
//! **Game Hub Integration:**
//! This game integrates with the Game Hub contract for session management and scoring.

use soroban_sdk::{
    Address, Bytes, BytesN, Env, IntoVal, String, Vec, contract, contractclient, contracterror,
    contractimpl, contracttype, symbol_short, vec,
};

// Import GameHub contract interface
#[contractclient(name = "GameHubClient")]
pub trait GameHub {
    fn start_game(
        env: Env,
        game_id: Address,
        session_id: u32,
        player1: Address,
        player2: Address,
        player1_points: i128,
        player2_points: i128,
    );

    fn end_game(env: Env, session_id: u32, player1_won: bool);
}

// Import ZK Verifier contract interface
#[contractclient(name = "VerifierClient")]
pub trait Verifier {
    fn verify(env: Env, proof: Bytes, public_inputs: Bytes) -> bool;
}

// ============================================================================
// Errors
// ============================================================================

#[contracterror]
#[derive(Copy, Clone, Debug, Eq, PartialEq, PartialOrd, Ord)]
#[repr(u32)]
pub enum Error {
    GameNotFound = 1,
    NotPlayer = 2,
    GameNotStarted = 3,
    GameAlreadyEnded = 4,
    InvalidMove = 5,
    NotDefender = 6,
    NotAttacker = 7,
    MoveAlreadyMade = 8,
    DefenderMustCommit = 9,
    InvalidProof = 10,
    AllMovesCompleted = 11,
    GameNotComplete = 12,
}

// ============================================================================
// Data Types
// ============================================================================

const GRID_SIZE: u32 = 8;
const MAX_MOVES: u32 = 64; // 8x8 grid

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Game {
    pub defender: Address,        // Player A
    pub attacker: Address,        // Player B
    pub defender_points: i128,
    pub attacker_points: i128,
    pub trap_merkle_root: BytesN<32>, // Commitment to trap grid
    pub moves_made: u32,
    pub hits: u32,
    pub misses: u32,
    pub game_started: bool,
    pub game_ended: bool,
    pub winner: Option<Address>,
}

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Move {
    pub x: u32,
    pub y: u32,
    pub is_hit: bool,
    pub verified: bool,
}

#[contracttype]
#[derive(Clone)]
pub enum DataKey {
    Game(u32),
    Moves(u32), // session_id -> Vec<Move>
    GameHubAddress,
    VerifierAddress,
    Admin,
}

// ============================================================================
// Storage TTL Management
// ============================================================================

const GAME_TTL_LEDGERS: u32 = 518_400; // 30 days

// ============================================================================
// Contract Definition
// ============================================================================

#[contract]
pub struct TrapGridContract;

#[contractimpl]
impl TrapGridContract {
    /// Initialize the contract with GameHub, Verifier addresses and admin
    pub fn __constructor(
        env: Env,
        admin: Address,
        game_hub: Address,
        verifier: Address,
    ) {
        env.storage().instance().set(&DataKey::Admin, &admin);
        env.storage()
            .instance()
            .set(&DataKey::GameHubAddress, &game_hub);
        env.storage()
            .instance()
            .set(&DataKey::VerifierAddress, &verifier);
    }

    /// Start a new game between defender and attacker with trap grid commitment
    ///
    /// # Arguments
    /// * `session_id` - Unique session identifier
    /// * `defender` - Player A who sets up traps
    /// * `attacker` - Player B who makes moves
    /// * `trap_merkle_root` - Merkle root commitment of trap grid
    /// * `defender_points` - Points committed by defender
    /// * `attacker_points` - Points committed by attacker
    pub fn start_game(
        env: Env,
        session_id: u32,
        defender: Address,
        attacker: Address,
        trap_merkle_root: BytesN<32>,
        defender_points: i128,
        attacker_points: i128,
    ) -> Result<(), Error> {
        // Prevent self-play
        if defender == attacker {
            panic!("Cannot play against yourself");
        }

        // Require authentication from both players
        defender.require_auth_for_args(vec![
            &env,
            session_id.into_val(&env),
            defender_points.into_val(&env),
        ]);
        attacker.require_auth_for_args(vec![
            &env,
            session_id.into_val(&env),
            attacker_points.into_val(&env),
        ]);

        // Get GameHub address
        let game_hub_addr: Address = env
            .storage()
            .instance()
            .get(&DataKey::GameHubAddress)
            .expect("GameHub address not set");

        // Create GameHub client and start game
        let game_hub = GameHubClient::new(&env, &game_hub_addr);
        game_hub.start_game(
            &env.current_contract_address(),
            &session_id,
            &defender,
            &attacker,
            &defender_points,
            &attacker_points,
        );

        // Create game state
        let game = Game {
            defender: defender.clone(),
            attacker: attacker.clone(),
            defender_points,
            attacker_points,
            trap_merkle_root,
            moves_made: 0,
            hits: 0,
            misses: 0,
            game_started: true,
            game_ended: false,
            winner: None,
        };

        // Store game state
        let game_key = DataKey::Game(session_id);
        env.storage().temporary().set(&game_key, &game);
        env.storage()
            .temporary()
            .extend_ttl(&game_key, GAME_TTL_LEDGERS, GAME_TTL_LEDGERS);

        // Initialize empty moves vector
        let moves_key = DataKey::Moves(session_id);
        let moves: Vec<Move> = vec![&env];
        env.storage().temporary().set(&moves_key, &moves);
        env.storage()
            .temporary()
            .extend_ttl(&moves_key, GAME_TTL_LEDGERS, GAME_TTL_LEDGERS);

        Ok(())
    }

    /// Attacker makes a move, and Defender responds with ZK proof
    ///
    /// # Arguments
    /// * `session_id` - Game session identifier
    /// * `x` - X coordinate of move (0-7)
    /// * `y` - Y coordinate of move (0-7)
    /// * `is_hit` - Defender's claim: true if trap hit, false if miss
    /// * `proof` - ZK proof of the claim
    /// * `public_inputs` - Public inputs for proof verification
    pub fn make_move(
        env: Env,
        session_id: u32,
        x: u32,
        y: u32,
        is_hit: bool,
        proof: Bytes,
        public_inputs: Bytes,
    ) -> Result<bool, Error> {
        // Load game
        let game_key = DataKey::Game(session_id);
        let mut game: Game = env
            .storage()
            .temporary()
            .get(&game_key)
            .ok_or(Error::GameNotFound)?;

        // Validate game state
        if !game.game_started {
            return Err(Error::GameNotStarted);
        }
        if game.game_ended {
            return Err(Error::GameAlreadyEnded);
        }

        // Validate move coordinates
        if x >= GRID_SIZE || y >= GRID_SIZE {
            return Err(Error::InvalidMove);
        }

        // Check if move already made
        let moves_key = DataKey::Moves(session_id);
        let mut moves: Vec<Move> = env
            .storage()
            .temporary()
            .get(&moves_key)
            .unwrap_or(vec![&env]);

        for i in 0..moves.len() {
            let existing_move = moves.get(i).unwrap();
            if existing_move.x == x && existing_move.y == y {
                return Err(Error::MoveAlreadyMade);
            }
        }

        // Verify ZK proof using the verifier contract
        let verifier_addr: Address = env
            .storage()
            .instance()
            .get(&DataKey::VerifierAddress)
            .expect("Verifier address not set");

        let verifier = VerifierClient::new(&env, &verifier_addr);
        let proof_valid = verifier.verify(&proof, &public_inputs);

        if !proof_valid {
            return Err(Error::InvalidProof);
        }

        // Record the move
        let new_move = Move {
            x,
            y,
            is_hit,
            verified: true,
        };
        moves.push_back(new_move);

        // Update game state
        game.moves_made += 1;
        if is_hit {
            game.hits += 1;
        } else {
            game.misses += 1;
        }

        // Check if game should end (all moves made or other condition)
        let game_complete = game.moves_made >= MAX_MOVES;

        if game_complete {
            game.game_ended = true;
            // Determine winner: defender wins if attacker couldn't find enough traps
            // (For this demo, let's say attacker needs > 50% hit rate to win)
            let attacker_wins = game.hits > (MAX_MOVES / 2);
            game.winner = if attacker_wins {
                Some(game.attacker.clone())
            } else {
                Some(game.defender.clone())
            };

            // Call GameHub to end game
            let game_hub_addr: Address = env
                .storage()
                .instance()
                .get(&DataKey::GameHubAddress)
                .expect("GameHub address not set");
            let game_hub = GameHubClient::new(&env, &game_hub_addr);
            game_hub.end_game(&session_id, &!attacker_wins); // true if defender won
        }

        // Save updated state
        env.storage().temporary().set(&game_key, &game);
        env.storage().temporary().set(&moves_key, &moves);
        env.storage()
            .temporary()
            .extend_ttl(&game_key, GAME_TTL_LEDGERS, GAME_TTL_LEDGERS);
        env.storage()
            .temporary()
            .extend_ttl(&moves_key, GAME_TTL_LEDGERS, GAME_TTL_LEDGERS);

        Ok(proof_valid)
    }

    /// End the game early (e.g., if attacker gives up or time limit reached)
    pub fn end_game(env: Env, session_id: u32) -> Result<(), Error> {
        let game_key = DataKey::Game(session_id);
        let mut game: Game = env
            .storage()
            .temporary()
            .get(&game_key)
            .ok_or(Error::GameNotFound)?;

        if game.game_ended {
            return Err(Error::GameAlreadyEnded);
        }

        // Determine winner based on current state
        let attacker_wins = game.hits > (game.moves_made / 2);
        game.winner = if attacker_wins {
            Some(game.attacker.clone())
        } else {
            Some(game.defender.clone())
        };
        game.game_ended = true;

        // Call GameHub to end game
        let game_hub_addr: Address = env
            .storage()
            .instance()
            .get(&DataKey::GameHubAddress)
            .expect("GameHub address not set");
        let game_hub = GameHubClient::new(&env, &game_hub_addr);
        game_hub.end_game(&session_id, &!attacker_wins);

        env.storage().temporary().set(&game_key, &game);
        Ok(())
    }

    /// Get game state
    pub fn get_game(env: Env, session_id: u32) -> Result<Game, Error> {
        let game_key = DataKey::Game(session_id);
        env.storage()
            .temporary()
            .get(&game_key)
            .ok_or(Error::GameNotFound)
    }

    /// Get all moves for a game
    pub fn get_moves(env: Env, session_id: u32) -> Vec<Move> {
        let moves_key = DataKey::Moves(session_id);
        env.storage()
            .temporary()
            .get(&moves_key)
            .unwrap_or(vec![&env])
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use soroban_sdk::testutils::Address as _;

    #[test]
    fn test_game_initialization() {
        let env = Env::default();
        let contract_id = env.register_contract(None, TrapGridContract);
        let client = TrapGridContractClient::new(&env, &contract_id);

        let admin = Address::generate(&env);
        let game_hub = Address::generate(&env);
        let verifier = Address::generate(&env);

        client.__constructor(&admin, &game_hub, &verifier);

        // Test basic initialization
        // Note: More comprehensive tests would require mock contracts for game_hub and verifier
    }
}
