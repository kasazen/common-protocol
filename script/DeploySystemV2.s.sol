// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/YieldDirector.sol";
import "../src/vaults/SmartVault.sol";
import "../src/adapters/UniswapAdapter.sol";

contract DeploySystemV2 is Script {
    function run() external {
        vm.startBroadcast();

        address USDC = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;

        // 1. Deploy Director V2
        YieldDirector director = new YieldDirector(USDC);
        console.log("DIRECTOR V2:", address(director));

        // 2. Deploy Vault V2
        SmartVault vault = new SmartVault(USDC);
        console.log("VAULT V2:   ", address(vault));

        // 3. Deploy Adapter V2
        UniswapAdapter adapter = new UniswapAdapter();
        console.log("ADAPTER V2: ", address(adapter));

        // --- WIRING ---
        // Connect Vault <-> Director
        vault.setDirector(address(director));
        director.setVault(address(vault));

        // Connect Director <-> Adapter
        director.setAdapter(address(adapter));

        console.log(">>> SYSTEM V2 FULLY WIRED <<<");

        vm.stopBroadcast();
    }
}
