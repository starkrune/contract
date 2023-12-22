use core::option::OptionTrait;
use core::traits::TryInto;
use core::clone::Clone;
use snforge_std::{
    declare, ContractClassTrait, start_prank, stop_prank, start_spoof, TxInfoMockTrait,
    cheatcodes::CheatTarget, test_address, get_class_hash
};
use starknet::{contract_address_const, ContractAddress, contract_address_to_felt252, account::Call};
use core::pedersen::{pedersen, PedersenTrait};
use core::array::SpanTrait;
use core::hash::HashStateTrait;
use alexandria_math::{BitShift, count_digits_of_base};
use core::integer::u256_checked_sub;
use starknet::class_hash_to_felt252;
use starknet::class_hash::ClassHash;
use openzeppelin::token::erc20::interface::{
    ISafeAllowanceDispatcher, ISafeAllowanceDispatcherTrait, IERC20Dispatcher, IERC20DispatcherTrait
};
use starkrune::rune::rune::{IRuneEtchingDispatcher, IRuneEtchingDispatcherTrait};
use starkrune::manager::indexer::{
    IRuneIndexerDispatcher, IRuneIndexerDispatcherTrait, IssuanceInfo
};
use starkrune::mock::test_erc20::{ITestERC20Dispatcher, ITestERC20DispatcherTrait};

fn deploy_indexer() -> (ContractAddress, ContractAddress) {
    let strk = declare('TestERC20');
    let strk_args = array!['Starknet Token', 'STRK'];
    let strk_address = strk.deploy(@strk_args).unwrap();

    let rune = declare('Rune');
    let rune_class_hash = rune.class_hash;

    let indexer = declare('RuneIndexer');

    let fee: felt252 = 1000000000000000000000; // 1000strk
    let fee_token = contract_address_to_felt252(strk_address);
    let rune_class_hash_felt = class_hash_to_felt252(rune_class_hash);

    let indexer_args = array![fee, fee_token, rune_class_hash_felt];
    let indexer_contract_address = indexer.deploy(@indexer_args).unwrap();
    (indexer_contract_address, strk_address)
}

#[test]
fn test_indexer_deploy() {
    let (indexer_address, fee_token_address) = deploy_indexer();

    let rune_index_dispatcher = IRuneIndexerDispatcher { contract_address: indexer_address };

    let (fee, fee_token) = rune_index_dispatcher.issuance_fee_info();
    assert(fee == 1000000000000000000000, 'fee is wrong');
    assert(fee_token == fee_token_address, 'fee token address is wrong');
}

fn issuance() -> (ContractAddress, ContractAddress, ContractAddress) {
    let (indexer_address, fee_token_address) = deploy_indexer();

    let caller_address: ContractAddress = contract_address_const::<'PROJECT'>();

    start_prank(CheatTarget::One(fee_token_address), caller_address);
    let strk_dispatcher = ITestERC20Dispatcher { contract_address: fee_token_address };
    strk_dispatcher.mint(2000000000000000000000); // 2000strk
    let strk_allownace = ISafeAllowanceDispatcher { contract_address: fee_token_address };
    strk_allownace.increase_allowance(indexer_address, 1000000000000000000000); // 1000strk
    stop_prank(CheatTarget::One(fee_token_address));

    start_prank(CheatTarget::One(indexer_address), caller_address);
    let rune_index_dispatcher = IRuneIndexerDispatcher { contract_address: indexer_address };
    let new_issuance = IssuanceInfo {
        term: 0,
        difficulty: 0,
        limit: 1000,
        max_supply: 10000000,
        fee: 1,
        name: 'Test',
        symbol: 'TEST',
        fee_token: fee_token_address,
        fee_recipient: test_address()
    };
    let rune_address = rune_index_dispatcher.issuance(new_issuance);
    stop_prank(CheatTarget::One(indexer_address));
    (rune_address, indexer_address, fee_token_address)
}

#[test]
fn test_rune_issuance() {
    let (rune_address, indexer_address, _) = issuance();

    let rune_index_dispatcher = IRuneIndexerDispatcher { contract_address: indexer_address };
    let read_address = rune_index_dispatcher.get_rune_address('Test');
    assert(read_address == rune_address, 'rune address is not recorded');
}

#[test]
fn use_can_etch_with_zero_difficulty() {
    let (rune_address, indexer_address, fee_token_address) = issuance();

    // mint token
    let caller_address: ContractAddress = contract_address_const::<'USER'>();
    start_prank(CheatTarget::One(fee_token_address), caller_address);
    let strk_dispatcher = ITestERC20Dispatcher { contract_address: fee_token_address };
    strk_dispatcher.mint(1);
    let strk_token = IERC20Dispatcher { contract_address: fee_token_address };
    strk_token.approve(spender: rune_address, amount: 1);
    stop_prank(CheatTarget::One(fee_token_address));

    // etch
    start_prank(CheatTarget::One(rune_address), caller_address);
    let rune_dispatcher = IRuneEtchingDispatcher { contract_address: rune_address };
    let rune_erc20_dispatcher = IERC20Dispatcher { contract_address: rune_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: fee_token_address };

    assert(rune_dispatcher.etch(1000), 'can not etch');
    assert(rune_erc20_dispatcher.balance_of(caller_address) == 1000, 'balance is not correct');
    stop_prank(CheatTarget::One(rune_address));
}
