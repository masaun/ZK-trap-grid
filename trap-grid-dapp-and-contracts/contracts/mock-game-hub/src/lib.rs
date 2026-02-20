#![no_std]

//! Mock Game Hub Contract
//! 
//! A simple mock implementation of a game hub for local development and testing.
//! This contract provides basic game registration and tracking functionality.

use soroban_sdk::{contract, contractimpl, contracttype, Address, Env, String, Vec};

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GameInfo {
    pub game_id: u64,
    pub game_contract: Address,
    pub name: String,
    pub active: bool,
}

#[contracttype]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DataKey {
    GameCount,
    Game(u64),
    GameContract(Address),
}

#[contract]
pub struct MockGameHub;

#[contractimpl]
impl MockGameHub {
    /// Initialize the game hub
    pub fn initialize(env: Env) {
        // Set initial game count to 0
        env.storage().persistent().set(&DataKey::GameCount, &0u64);
    }

    /// Register a new game contract
    pub fn register_game(
        env: Env,
        game_contract: Address,
        name: String,
    ) -> u64 {
        // Get and increment game count
        let mut game_count: u64 = env.storage()
            .persistent()
            .get(&DataKey::GameCount)
            .unwrap_or(0);
        
        game_count += 1;

        let game_info = GameInfo {
            game_id: game_count,
            game_contract: game_contract.clone(),
            name,
            active: true,
        };

        // Store game info
        env.storage().persistent().set(&DataKey::Game(game_count), &game_info);
        env.storage().persistent().set(&DataKey::GameContract(game_contract), &game_count);
        env.storage().persistent().set(&DataKey::GameCount, &game_count);

        game_count
    }

    /// Get game info by ID
    pub fn get_game(env: Env, game_id: u64) -> Option<GameInfo> {
        env.storage().persistent().get(&DataKey::Game(game_id))
    }

    /// Get game ID by contract address
    pub fn get_game_by_contract(env: Env, game_contract: Address) -> Option<u64> {
        env.storage().persistent().get(&DataKey::GameContract(game_contract))
    }

    /// Get total number of registered games
    pub fn get_game_count(env: Env) -> u64 {
        env.storage().persistent().get(&DataKey::GameCount).unwrap_or(0)
    }

    /// Get all games
    pub fn get_all_games(env: Env) -> Vec<GameInfo> {
        let game_count = Self::get_game_count(env.clone());
        let mut games = Vec::new(&env);

        for i in 1..=game_count {
            if let Some(game) = Self::get_game(env.clone(), i) {
                games.push_back(game);
            }
        }

        games
    }

    /// Deactivate a game
    pub fn deactivate_game(env: Env, game_id: u64) -> bool {
        if let Some(mut game_info) = env.storage().persistent().get::<DataKey, GameInfo>(&DataKey::Game(game_id)) {
            game_info.active = false;
            env.storage().persistent().set(&DataKey::Game(game_id), &game_info);
            true
        } else {
            false
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use soroban_sdk::{testutils::Address as _, Env, String};

    #[test]
    fn test_initialize_and_register() {
        let env = Env::default();
        let contract_id = env.register_contract(None, MockGameHub);
        let client = MockGameHubClient::new(&env, &contract_id);

        // Initialize
        client.initialize();

        // Register a game
        let game_contract = Address::generate(&env);
        let game_name = String::from_str(&env, "Trap Grid");
        let game_id = client.register_game(&game_contract, &game_name);

        assert_eq!(game_id, 1);
        assert_eq!(client.get_game_count(), 1);

        // Get game info
        let game_info = client.get_game(&game_id).unwrap();
        assert_eq!(game_info.game_id, 1);
        assert_eq!(game_info.game_contract, game_contract);
        assert_eq!(game_info.name, game_name);
        assert_eq!(game_info.active, true);
    }

    #[test]
    fn test_multiple_games() {
        let env = Env::default();
        let contract_id = env.register_contract(None, MockGameHub);
        let client = MockGameHubClient::new(&env, &contract_id);

        client.initialize();

        // Register multiple games
        let game1 = Address::generate(&env);
        let game2 = Address::generate(&env);

        client.register_game(&game1, &String::from_str(&env, "Game 1"));
        client.register_game(&game2, &String::from_str(&env, "Game 2"));

        assert_eq!(client.get_game_count(), 2);

        let all_games = client.get_all_games();
        assert_eq!(all_games.len(), 2);
    }
}
