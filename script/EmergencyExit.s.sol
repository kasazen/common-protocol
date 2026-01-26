// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/AccountantWithRateProviders.sol";
import "../src/core/TellerWithMultiAssetSupport.sol";

contract EmergencyExit is Script {
    function run(address accountantAddr, address tellerAddr) external {
        vm.startBroadcast();
        
        AccountantWithRateProviders(accountantAddr).togglePause();
        // Additional logic would go here to trigger Aave withdrawal via Manager
        
        console.log("SYSTEM PAUSED - EMERGENCY EXIT INITIATED");
        vm.stopBroadcast();
    }
}
