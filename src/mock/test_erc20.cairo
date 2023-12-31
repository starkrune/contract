#[starknet::interface]
trait ITestERC20<TState> {
    fn mint(ref self: TState, amount: u256,);
}

#[starknet::contract]
mod TestERC20 {
    use openzeppelin::token::erc20::ERC20Component;
    use starknet::{ContractAddress, get_caller_address};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    #[abi(embed_v0)]
    impl SafeAllowanceImpl = ERC20Component::SafeAllowanceImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl SafeAllowanceCamelImpl =
        ERC20Component::SafeAllowanceCamelImpl<ContractState>;
    impl InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252) {
        self.erc20.initializer(name, symbol);
    }

    #[external(v0)]
    impl TestERC20Impl of super::ITestERC20<ContractState> {
        fn mint(ref self: ContractState, amount: u256) {
            self.erc20._mint(get_caller_address(), amount);
        }
    }
}
