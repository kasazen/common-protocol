// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/YieldDirector.sol";
import "../src/vaults/SmartVault.sol";
import "../src/adapters/UniswapAdapter.sol";

contract DeploySystemV3 is Script {
    function run() external {
        vm.startBroadcast();

        address USDC = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;

        console.log("--- DEPLOYING SYSTEM V3 (Router02 Compliant) ---");

        // 1. Deploy Brain, Body, Muscle
        YieldDirector director = new YieldDirector(USDC);
        SmartVault vault = new SmartVault(USDC);
        UniswapAdapter adapter = new UniswapAdapter();

        console.log("Director V3:", address(director));
        console.log("Vault V3:   ", address(vault));
        console.log("Adapter V3: ", address(adapter));

        // 2. Wire them up
        vault.setDirector(address(director));
        director.setVault(address(vault));
        director.setAdapter(address(adapter));

        console.log(">>> WIRED SUCCESSFULLY <<<");

        vm.stopBroadcast();
    }
}
