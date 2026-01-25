// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/YieldDirector.sol";
import "../src/vaults/SmartVault.sol";

contract DebugRebalance is Script {
    function run() external {
        // 1. Load Your V2 Contracts (Verified from Integrity Check)
        address DIRECTOR_ADDR = 0x07B9B16f887bc1C66C204dE544F249Bc819911Dc;
        address VAULT_ADDR    = 0xB8AB1d5ee8828Ed201ae598ec3DF92632CEA8D67;

        YieldDirector director = YieldDirector(DIRECTOR_ADDR);

        vm.startBroadcast();

        console.log("--- DEBUGGER STARTED ---");
        console.log("Attempting Rebalance Simulation...");
        
        // 2. Try to run the code and catch the specific crash reason
        try director.rebalance() {
            console.log("[SUCCESS] Rebalance worked in simulation!");
        } catch Error(string memory reason) {
            // This catches standard reverts like require(..., "Message")
            console.log("[FAILED] Revert Reason:", reason);
        } catch (bytes memory lowLevelData) {
            // This catches low-level crashes (like Uniswap internal errors)
            console.log("[FAILED] Low Level Crash.");
            console.log("This usually means: 1. Slippage, 2. Locked Pool, or 3. Approval Issue");
            if (lowLevelData.length > 0) {
                 console.logBytes(lowLevelData);
            }
        }

        vm.stopBroadcast();
        console.log("--- DEBUGGER END ---");
    }
}
