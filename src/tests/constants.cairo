use starknet::ClassHash;
use starknet::ContractAddress;
use starknet::class_hash_const;
use starknet::contract_address_const;
use core::integer::BoundedU128;

const DIFFICULTY: u128 = 0x4e414d45;
const DIVISIBILITY: u8 = 18_u8;
const END: u32 = 3;
const FEE: u256 = 0;
const ID: u16 = 1;
const SYMBOL: u8 = 162; // ¢
const SUPPLY: u256 = 21000000;
const LIMIT: u128 = 1000_u128;
const RUNE: felt252 = 'Stark Rune';
