// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/AccountantWithRateProviders.sol";

contract EmergencyExit is Script {
    function run(address accountantAddr) external {
        vm.startBroadcast();
        // Fixed: Ensure we call the correct function on the Accountant
        AccountantWithRateProviders(accountantAddr).togglePause();
        console.log("SYSTEM PAUSED - EMERGENCY EXIT INITIATED");
        vm.stopBroadcast();
    }
}
