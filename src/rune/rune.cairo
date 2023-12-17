#[starknet::component]
mod RuneComponent {
    use openzeppelin::introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::ContractAddress;
    use starkrune::rune::interface::{
        Etching, IRuneEtching, RuneInfo, IRuneInfo, IRUNE_ETCHING_ID, IRUNE_INFO_ID, Rune
    };

    #[storage]
    struct Storage {
        Rune_burned: u128,
        Rune_difficulty: u128,
        Rune_divisibility: u8,
        Rune_end: u32,
        Rune_etching: felt252, // tx hash
        Rune_fee: u256,
        Rune_height: u64,
        Rune_id: u16,
        Rune_limit: u128,
        Rune_number: u64,
        Rune_rune: Rune,
        Rune_spacers: u32,
        Rune_supply: u128,
        Rune_symbol: u8,
        Rune_timestamp: u64,
        Rune_balances: LegacyMap<ContractAddress, u128>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[derive(Drop, starknet::Event)]
    struct RuneEtched {
        #[key]
        operator: ContractAddress,
        etch: Etching
    }

    mod Errors {
        const INVALID_ACCOUNT: felt252 = 'Rune: invalid account';
    }

    #[embeddable_as(RuneEtchingImpl)]
    impl RuneEtching<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IRuneEtching<ComponentState<TContractState>> {
        fn etch(self: @ComponentState<TContractState>, etching: Etching) -> felt252 {
            // return tx hash
            0
        }
    }

    #[embeddable_as(RuneInfoImpl)]
    impl GetRuneInfo<
        TContractState,
        +HasComponent<TContractState>,
        +SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of IRuneInfo<ComponentState<TContractState>> {
        fn info(self: @ComponentState<TContractState>, rune: u128) -> RuneInfo {
            RuneInfo {
                burned: self.Rune_burned.read(),
                difficulty: self.Rune_difficulty.read(),
                divisibility: self.Rune_divisibility.read(),
                end: self.Rune_end.read(),
                etching: self.Rune_etching.read(),
                fee: self.Rune_fee.read(),
                height: self.Rune_height.read(),
                id: self.Rune_id.read(),
                limit: self.Rune_limit.read(),
                number: self.Rune_number.read(),
                rune: self.Rune_rune.read(),
                spacers: self.Rune_spacers.read(),
                supply: self.Rune_supply.read(),
                symbol: self.Rune_symbol.read(),
                timestamp: self.Rune_timestamp.read(),
            }
        }
    }


    //
    // Internal
    //

    #[generate_trait]
    impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>,
        +Drop<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            difficulty: u128,
            divisibility: u8,
            end: u32,
            fee: u256,
            id: u16,
            limit: Rune,
            rune: u128,
            spacers: u32,
            symbol: u8,
        ) {
            let tx_info = starknet::get_tx_info().unbox();
            let block_info = starknet::get_block_info().unbox();
            let tx_hash = tx_info.transaction_hash;

            self.Rune_burned.write(0);
            self.Rune_difficulty.write(difficulty);
            self.Rune_divisibility.write(divisibility);
            self.Rune_end.write(end);
            self.Rune_etching.write(tx_hash);
            self.Rune_fee.write(fee);
            self.Rune_height.write(block_info.block_number);
            self.Rune_id.write(id);
            self.Rune_limit.write(limit);
            self.Rune_number.write(0);
            self.Rune_rune.write(rune);
            self.Rune_spacers.write(spacers);
            self.Rune_supply.write(0);
            self.Rune_symbol.write(symbol);
            self.Rune_timestamp.write(block_info.block_timestamp);

            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(IRUNE_ETCHING_ID);
            src5_component.register_interface(IRUNE_INFO_ID);
        }
    }
}
