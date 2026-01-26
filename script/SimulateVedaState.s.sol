// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/base/BoringVault.sol";
import "../src/core/ManagerWithMerkleVerification.sol";
import "../src/core/TellerWithMultiAssetSupport.sol";
import "../src/core/AccountantWithRateProviders.sol";
import "../src/core/RevenueSplitter.sol";
import "../src/hooks/WorldIDHook.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract SimulateVedaState is Script {
    function run() external {
        vm.startBroadcast();
        
        MockERC20 usdc = new MockERC20("USDC", "USDC", 6);
        WorldIDHook hook = new WorldIDHook();
        RevenueSplitter splitter = new RevenueSplitter(msg.sender, address(0x123)); 
        
        // Match 4 arguments: Owner, Asset, Hook, Splitter
        AccountantWithRateProviders accountant = new AccountantWithRateProviders(
            msg.sender, 
            address(usdc), 
            address(hook), 
            address(splitter)
        );
        
        BoringVault vault = new BoringVault(payable(msg.sender), "Veda", "vWY", usdc);
        ManagerWithMerkleVerification manager = new ManagerWithMerkleVerification(msg.sender, address(vault));
        TellerWithMultiAssetSupport teller = new TellerWithMultiAssetSupport(msg.sender, address(vault), address(accountant));

        accountant.setTeller(address(teller));
        vault.setManager(address(manager)); 
        
        vm.stopBroadcast();
    }
}
