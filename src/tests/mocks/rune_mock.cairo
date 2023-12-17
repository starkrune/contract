#[starknet::contract]
mod RuneMock {
    use openzeppelin::introspection::src5::SRC5Component;
    use starkrune::rune::RuneComponent;

    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: RuneComponent, storage: rune, event: RuneEvent);

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // Rune
    #[abi(embed_v0)]
    impl RuneEtchingImpl = RuneComponent::RuneEtchingImpl<ContractState>;
    #[abi(embed_v0)]
    impl RuneInfoImpl = RuneComponent::RuneInfoImpl<ContractState>;
    impl RuneInternalImpl = RuneComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        rune: RuneComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        RuneEvent: RuneComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        difficulty: u128,
        divisibility: u8,
        end: u32,
        fee: u256,
        id: u16,
        limit: u128,
        rune: u128,
        spacers: u32,
        symbol: u8,
    ) {
        self
            .rune
            .initializer(difficulty, divisibility, end, fee, id, limit, rune, spacers, symbol,);
    }
}
