#[starknet::interface]
trait IRuneEtching<TState> {
    fn end(self: @TState) -> u64;
    fn difficulty(self: @TState) -> u128;
    fn limit(self: @TState) -> u128;
    fn max_supply(self: @TState) -> u256;
    fn fee(self: @TState) -> u256;
    fn etch(ref self: TState, limit: u128) -> bool;
}

#[starknet::contract]
mod Rune {
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::token::erc20::interface::{
        IERC20, IERC20Dispatcher, IERC20DispatcherTrait, IERC20Metadata
    };
    use starknet::{ContractAddress, get_caller_address};
    use core::integer::{BoundedInt, u256_from_felt252};
    use alexandria_math::{BitShift, count_digits_of_base};
    use super::IRuneEtching;

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;

    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        end: u64,
        difficulty: u128,
        limit: u128,
        max_supply: u256,
        fee: u256,
        fee_token: ContractAddress,
        deployer: ContractAddress,
        used_hash: LegacyMap<felt252, bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: felt252,
        symbol: felt252,
        term: u64,
        difficulty: u128,
        limit: u128,
        max_supply: u256,
        fee: u256,
        fee_token: ContractAddress,
        deployer: ContractAddress,
    ) {
        let block_number = starknet::info::get_block_number();
        self.erc20.initializer(name, symbol);
        if term == 0 {
            self.end.write(BoundedInt::max());
        } else {
            self.end.write(block_number + term);
        }
        self.difficulty.write(difficulty);
        self.limit.write(limit);
        self.max_supply.write(max_supply);
        self.fee.write(fee);
        self.fee_token.write(fee_token);
        self.deployer.write(deployer);
    }

    #[external(v0)]
    impl RuneEtchingImpl of super::IRuneEtching<ContractState> {
        fn end(self: @ContractState) -> u64 {
            self.end.read()
        }

        fn difficulty(self: @ContractState) -> u128 {
            self.difficulty.read()
        }

        fn limit(self: @ContractState) -> u128 {
            self.limit.read()
        }

        fn max_supply(self: @ContractState) -> u256 {
            self.max_supply.read()
        }

        fn fee(self: @ContractState) -> u256 {
            self.fee.read()
        }

        fn etch(ref self: ContractState, limit: u128) -> bool {
            assert(limit <= self.limit.read(), 'limit exceeded');
            assert(limit.into() + self.total_supply() <= self.max_supply(), 'max supply reached');
            let execute_info = starknet::info::get_execution_info().unbox();

            let block_number = execute_info.block_info.unbox().block_number;
            assert(block_number <= self.end.read(), 'etching is over');

            let tx_hash = execute_info.tx_info.unbox().transaction_hash;
            // difficulty check
            let difficulty = self.difficulty.read();
            if difficulty != 0 {
                let high = u256_from_felt252(tx_hash).high;
                let prefix = self.difficulty.read();
                let size = count_digits_of_base(prefix, 16);
                let head_letter = BitShift::shr(
                    high, count_digits_of_base(high, 16) * 4 - size * 4
                );
                assert(head_letter == prefix, 'not enough difficulty');
            }

            assert(!self.used_hash.read(tx_hash), 'multicall is not allowed');

            // pay fee
            let caller = get_caller_address();
            let fee = self.fee.read();
            if fee > 0 {
                let fee_token_dispatcher = IERC20Dispatcher {
                    contract_address: self.fee_token.read()
                };
                assert(
                    fee_token_dispatcher.transfer_from(caller, self.deployer.read(), fee),
                    'pay fee failed'
                );
            }

            // mark tx as used
            self.used_hash.write(tx_hash, true);

            // mint token
            self.erc20._mint(caller, limit.into());

            true
        }
    }
}
