// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/adapters/UniswapAdapter.sol";
import "../src/core/YieldDirector.sol";

contract DeployUniswapAdapter is Script {
    function run() external {
        vm.startBroadcast();

        // 1. Load your EXISTING Director Address
        // (From your previous logs: 0x56908D0865806ca95791dfeD74712152193c0ec7)
        address directorAddress = 0x56908D0865806ca95791dfeD74712152193c0ec7;
        YieldDirector director = YieldDirector(directorAddress);

        console.log("Using Existing Director:", directorAddress);

        // 2. Deploy the new Uniswap Adapter
        UniswapAdapter uniAdapter = new UniswapAdapter(directorAddress);
        console.log("New Uniswap Adapter Deployed:", address(uniAdapter));

        // 3. The Hot Swap: Connect Director -> Uniswap Adapter
        director.setAdapter(address(uniAdapter));
        console.log("Director successfully re-wired to Uniswap!");

        vm.stopBroadcast();
    }
}
