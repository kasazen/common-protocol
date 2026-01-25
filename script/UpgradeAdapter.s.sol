// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/core/YieldDirector.sol";
import "../src/adapters/UniswapAdapter.sol";

contract UpgradeAdapter is Script {
    function run() external {
        vm.startBroadcast();

        // 1. Load Existing Director
        address DIRECTOR = 0x07B9B16f887bc1C66C204dE544F249Bc819911Dc;

        // 2. Deploy NEW Path-Based Adapter
        UniswapAdapter newAdapter = new UniswapAdapter();
        console.log("NEW ADAPTER DEPLOYED:", address(newAdapter));

        // 3. Update Director to use new Adapter
        YieldDirector(DIRECTOR).setAdapter(address(newAdapter));
        console.log("Director connected to New Adapter.");

        vm.stopBroadcast();
    }
}
