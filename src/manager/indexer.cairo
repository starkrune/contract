use starknet::{ContractAddress, ClassHash, StorePacking};

#[starknet::interface]
trait IRuneIndexer<TState> {
    fn issuance(ref self: TState, info: IssuanceInfo) -> ContractAddress;
    fn issuance_fee_info(self: @TState) -> (u256, ContractAddress);
    fn get_rune_address(self: @TState, name: felt252) -> ContractAddress;
    fn get_rune_info(self: @TState, name: felt252) -> IssuanceInfo;
    fn owner(self: @TState) -> ContractAddress;
    fn upgrade(ref self: TState, new_class_hash: ClassHash) -> bool;
}


#[derive(Clone, Destruct, Drop, PartialEq, Serde, starknet::Store)]
struct IssuanceInfo {
    fee_token: ContractAddress,
    fee_recipient: ContractAddress,
    symbol: felt252,
    name: felt252,
    term: u64,
    limit: u64,
    difficulty: u128,
    max_supply: u256,
    fee: u256,
    token_address: ContractAddress,
}

#[starknet::contract]
mod RuneIndexer {
    use core::result::ResultTrait;
    use core::array::ArrayTrait;
    use core::traits::{Into, TryInto};
    use option::OptionTrait;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::upgradeable::UpgradeableComponent;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::{
        ContractAddress, get_caller_address, deploy_syscall, ClassHash, contract_address_to_felt252,
    };
    use starkrune::rune::Rune;
    use super::IssuanceInfo;

    component!(path: OwnableComponent, storage: ownable, event: OwnerEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        rune_class_hash: ClassHash,
        fee_token: ContractAddress,
        fee: u256,
        runes_address: LegacyMap<felt252, ContractAddress>,
        runes_info: LegacyMap<felt252, IssuanceInfo>,
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnerEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        CreatedRune: CreatedRune
    }

    #[derive(Drop, starknet::Event)]
    struct CreatedRune {
        fee_token: ContractAddress,
        fee_recipient: ContractAddress,
        #[key]
        name: felt252,
        symbol: felt252,
        term: u64,
        limit: u64,
        difficulty: u128,
        max_supply: u256,
        fee: u256,
        token_address: ContractAddress,
    }


    #[constructor]
    fn constructor(
        ref self: ContractState,
        fee: felt252,
        fee_token: ContractAddress,
        class_hash: ClassHash,
        owner: ContractAddress
    ) {
        self.ownable.initializer(owner);
        self.fee.write(fee.into());
        self.fee_token.write(fee_token);
        self.rune_class_hash.write(class_hash);
    }

    #[external(v0)]
    impl IRuneIndexerImpl of super::IRuneIndexer<ContractState> {
        fn issuance(ref self: ContractState, info: IssuanceInfo) -> ContractAddress {
            let caller = get_caller_address();

            let mut tmp_info = info.clone();
            let rune_address = self.runes_address.read(info.name);
            assert(rune_address.is_zero(), 'Rune already exists');

            // pay issuance fee
            let fee_token_dispatcher = IERC20Dispatcher { contract_address: self.fee_token.read() };
            assert(
                fee_token_dispatcher
                    .transfer_from(
                        caller, self.ownable.Ownable_owner.read(), self.fee.read().into(),
                    ),
                'pay issuance fee failed'
            );

            let (contract_address, _) = deploy_syscall(
                class_hash: self.rune_class_hash.read(),
                contract_address_salt: 0,
                calldata: array![
                    info.name,
                    info.symbol,
                    info.term.into(),
                    info.difficulty.into(),
                    info.limit.into(),
                    info.max_supply.low.into(),
                    info.max_supply.high.into(),
                    info.fee.low.into(),
                    info.fee.high.into(),
                    contract_address_to_felt252(info.fee_token),
                    contract_address_to_felt252(info.fee_recipient),
                ]
                    .span(),
                deploy_from_zero: false
            )
                .expect('issuance new rune failed');
            self.runes_address.write(info.name, contract_address);
            tmp_info.token_address = contract_address;
            self.runes_info.write(info.name, tmp_info);
            self
                .emit(
                    CreatedRune {
                        fee_token: info.fee_token,
                        fee_recipient: info.fee_recipient,
                        name: info.name,
                        symbol: info.symbol,
                        term: info.term,
                        limit: info.limit,
                        difficulty: info.difficulty,
                        max_supply: info.max_supply,
                        fee: info.fee,
                        token_address: contract_address
                    }
                );
            contract_address
        }

        fn issuance_fee_info(self: @ContractState) -> (u256, ContractAddress) {
            (self.fee.read(), self.fee_token.read())
        }

        fn get_rune_address(self: @ContractState, name: felt252) -> ContractAddress {
            self.runes_address.read(name)
        }

        fn get_rune_info(self: @ContractState, name: felt252) -> IssuanceInfo {
            self.runes_info.read(name)
        }

        fn owner(self: @ContractState) -> ContractAddress {
            self.ownable.Ownable_owner.read()
        }

        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) -> bool {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(new_class_hash);
            true
        }
    }
}
