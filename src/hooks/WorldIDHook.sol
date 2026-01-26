// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WorldIDHook {
    address public constant WORLD_ID_ROUTER = 0x17B354dD2595411ff79041f930e491A4Df39A278;

    function beforeDeposit(address, uint256) external view {
        // Verification logic placeholder
        // In production, we call IWorldIDRouter(WORLD_ID_ROUTER).verifyProof(...)
    }
}
