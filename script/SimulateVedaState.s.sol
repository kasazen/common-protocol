// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/base/BoringVault.sol";
import "../src/core/ManagerWithMerkleVerification.sol";
import "../src/core/TellerWithMultiAssetSupport.sol";
import "../src/core/AccountantWithRateProviders.sol";
import "../src/hooks/WorldIDHook.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract SimulateVedaState is Script {
    function run() external {
        address USDC_ADDR = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1; 
        ERC20 usdc;

        vm.startBroadcast();
        
        // AUTO-MOCK: If Real USDC is missing, deploy a Fake one.
        if (USDC_ADDR.code.length == 0) {
            console.log("--- MOCKING USDC (Local Env Detected) ---");
            MockERC20 mock = new MockERC20("USDC", "USDC", 6);
            usdc = ERC20(address(mock));
        } else {
            console.log("--- USING REAL USDC (Fork Detected) ---");
            usdc = ERC20(USDC_ADDR);
        }
        console.log("--- 1. DEPLOYING INFRASTRUCTURE ---");
        
        BoringVault vault = new BoringVault(msg.sender, "Veda World Yield", "vWY", usdc);
        WorldIDHook hook = new WorldIDHook();
        AccountantWithRateProviders accountant = new AccountantWithRateProviders(msg.sender, address(usdc));
        
        ManagerWithMerkleVerification manager = new ManagerWithMerkleVerification(msg.sender, address(vault));
        TellerWithMultiAssetSupport teller = new TellerWithMultiAssetSupport(msg.sender, address(vault), address(hook));

        console.log("Vault:", address(vault));
        console.log("Manager:", address(manager));

        // Wiring
        vault.setManager(address(manager)); 
        vault.transferOwnership(address(teller)); 

        console.log("--- 2. WIRING COMPLETE ---");
        vm.stopBroadcast();
    }
}
