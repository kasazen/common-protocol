// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/vaults/SmartVault.sol";
import "../src/core/YieldDirector.sol";

contract DeployFixedVault is Script {
    function run() external {
        vm.startBroadcast();

        address USDC = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        
        // 1. Load Existing Director (The Brain is fine)
        address directorAddr = 0x56908D0865806ca95791dfeD74712152193c0ec7;
        
        // 2. Deploy NEW SmartVault (The Body was broken)
        SmartVault newVault = new SmartVault(USDC, directorAddr);
        console.log("NEW SmartVault Deployed at:", address(newVault));

        // 3. Connect Director to new Vault
        YieldDirector(directorAddr).setVault(address(newVault));
        console.log("Director connected to new Vault");

        vm.stopBroadcast();
    }
}
