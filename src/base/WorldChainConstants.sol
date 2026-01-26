// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library WorldChainConstants {
    // Verified Infrastructure
    address internal constant NATIVE_USDC = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
    address internal constant WETH = 0x4200000000000000000000000000000000000006;
    address internal constant UNISWAP_ROUTER = 0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6;
    address internal constant UNISWAP_FACTORY = 0x7a5028BDa40e7B173C278C5342087826455ea25a;
    
    // Veda Safety Constants
    uint256 internal constant ONE_BPS = 0.0001e18;
    uint256 internal constant MAX_DEVIATION = 0.001e18;
}
