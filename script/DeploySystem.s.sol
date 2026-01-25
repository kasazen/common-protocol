// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/YieldDirector.sol";
import "../src/adapters/FlexibleAdapter.sol";

contract DeploySystem is Script {
    function run() external {
        vm.startBroadcast();

        address usdc = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        // CHANGE THIS when we move to Phase 1 (Morpho)
        address yieldSource = 0x63Daf86E82b6a9F62A21DcB024f163dC0c096f19; 
        
        YieldDirector director = new YieldDirector();
        console.log("New Director Deployed:", address(director));

        FlexibleAdapter adapter = new FlexibleAdapter(usdc, yieldSource, address(director));
        console.log("New Adapter Deployed:", address(adapter));

        director.setAdapter(address(adapter));
        console.log("Director configured with Adapter");

        vm.stopBroadcast();
    }
}
