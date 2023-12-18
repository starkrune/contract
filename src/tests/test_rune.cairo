use starkrune::rune::interface;
use starkrune::rune::RuneComponent;
use starkrune::rune::RuneComponent::{InternalImpl, RuneInfoImpl};
use openzeppelin::introspection::src5::SRC5Component::SRC5Impl;
use starkrune::tests::mocks::rune_mock::RuneMock;
use starkrune::tests::constants::{DIFFICULTY, DIVISIBILITY, END, FEE, ID, LIMIT, RUNE, SYMBOL};
use starknet::testing;

//
// Setup
//

type ComponentState = RuneComponent::ComponentState<RuneMock::ContractState>;

fn CONTRACT_STATE() -> RuneMock::ContractState {
    RuneMock::contract_state_for_testing()
}
fn COMPONENT_STATE() -> ComponentState {
    RuneComponent::component_state_for_testing()
}

fn setup() -> ComponentState {
    let mut state = COMPONENT_STATE();
    state.initializer(DIFFICULTY, DIVISIBILITY, END, FEE, ID, LIMIT, RUNE, SYMBOL);
    state
}


//
// Initializers
//

#[test]
#[available_gas(800000)]
fn test_initialize() {
    let mut state = COMPONENT_STATE();
    let mock_state = CONTRACT_STATE();

    state.initializer(DIFFICULTY, DIVISIBILITY, END, FEE, ID, LIMIT, RUNE, SYMBOL);
    let info = state.info(RUNE);
    assert(info.difficulty == DIFFICULTY, 'Invalid difficulty');
    assert(info.divisibility == DIVISIBILITY, 'Invalid divisibility');
    assert(info.end == END, 'Invalid end');
    assert(info.fee == FEE, 'Invalid fee');
    assert(info.id == ID, 'Invalid id');
    assert(info.limit == LIMIT, 'Invalid limit');
    assert(info.rune == RUNE, 'Invalid rune');
    assert(info.symbol == SYMBOL, 'Invalid symbol');
    assert(info.burned == 0, 'Invalid burned');
    assert(info.supply == 0, 'Invalid supply');
    assert(mock_state.supports_interface(interface::IRUNE_ETCHING_ID), 'Missing interface ID');
    assert(mock_state.supports_interface(interface::IRUNE_INFO_ID), 'Missing interface ID');
}

