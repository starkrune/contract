use starknet::ContractAddress;

// NEED update if interface changed
const IRUNE_ETCHING_ID: felt252 = 0x38532670b97b4da43510c78e9b61dac9b4142355920ef5c8b81b4ed60616fd0;
const IRUNE_INFO_ID: felt252 = 0x2f86d2614c0ae7a24c9f7f405822ad1480fc06af84c5443a0218544a2fa819d;

type Rune = felt252;

#[derive(Clone, Copy, Debug, Destruct, Drop, PartialEq, Serde)]
struct Etching {
    divisibility: u8,
    difficulty: u128,
    fee: u256,
    rune: Rune,
    supply: u128,
    symbol: u8,
    term: u32
}

#[starknet::interface]
trait IRuneEtching<TState> {
    fn etch(self: @TState, etching: Etching) -> felt252;
}

#[derive(Clone, Copy, Debug, Destruct, Drop, PartialEq, Serde)]
struct RuneInfo {
    burned: u128, // burned supply
    divisibility: u8, // dicimal
    difficulty: u128, // difficulty of rune, e.g. 12345=0x3039, hash must be start with 0x3039
    end: u32, // end of rune
    etching: felt252, // tx hash
    fee: u256, // fee paid to etch
    height: u64, // create height
    id: u16, // rune id
    limit: u128, // limit per rune
    number: u64, // number of runes
    rune: Rune, // rune name
    supply: u128, // max supply
    symbol: u8, // rune symbol
    timestamp: u64 // timestamp of rune creation
}

#[starknet::interface]
trait IRuneInfo<TState> {
    fn info(self: @TState, rune: Rune) -> RuneInfo;
}
