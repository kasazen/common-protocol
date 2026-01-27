// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BoringVault} from "../src/base/BoringVault.sol";
import {ManagerWithMerkleVerification} from "../src/core/ManagerWithMerkleVerification.sol";
import {TellerWithMultiAssetSupport} from "../src/core/TellerWithMultiAssetSupport.sol";
import {AccountantWithRateProviders} from "../src/core/AccountantWithRateProviders.sol";
import {RevenueSplitter} from "../src/core/RevenueSplitter.sol";
import {VedaArcticLens} from "../src/core/VedaArcticLens.sol";
import {WorldIDHook} from "../src/hooks/WorldIDHook.sol";
import {MorphoBlueDecoder} from "../src/decoders/MorphoBlueDecoder.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract DeployVedaArctic is Script {
    function run() external {
        // ---------------------------------------------------------
        // 1. Configuration (World Chain Mainnet Constants)
        // ---------------------------------------------------------
        address usdcAddr = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        
        // Canonical Morpho Blue (Check on WorldScan)
        address morphoBlueAddr = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
        
        // ---------------------------------------------------------
        // 2. Deploy Infrastructure
        // ---------------------------------------------------------
        vm.startBroadcast();

        address mainOwner = msg.sender;
        // Placeholder for Partner Wallet (Replace with real Gnosis Safe in prod)
        address partnerWallet = address(0xDEAFBEEF); 

        // Core Components
        WorldIDHook hook = new WorldIDHook();
        RevenueSplitter splitter = new RevenueSplitter(mainOwner, partnerWallet);
        VedaArcticLens lens = new VedaArcticLens();

        // The Brain (Updated with Tiered Loyalty)
        AccountantWithRateProviders accountant = new AccountantWithRateProviders(
            mainOwner, usdcAddr, address(hook), address(splitter)
        );

        // The Vault (Asset Container)
        BoringVault vault = new BoringVault(payable(mainOwner), "Veda Arctic USDC", "vUSDC", ERC20(usdcAddr));

        // The Manager (Security Layer)
        ManagerWithMerkleVerification manager = new ManagerWithMerkleVerification(
            mainOwner, address(vault)
        );

        // The Teller (Human Gate)
        TellerWithMultiAssetSupport teller = new TellerWithMultiAssetSupport(
            mainOwner, address(vault), address(accountant)
        );

        // ---------------------------------------------------------
        // 3. Safety Equipment (Decoders)
        // ---------------------------------------------------------
        MorphoBlueDecoder morphoDecoder = new MorphoBlueDecoder(morphoBlueAddr, usdcAddr);

        // ---------------------------------------------------------
        // 4. Wiring & Permissions
        // ---------------------------------------------------------
        accountant.setTeller(address(teller));
        vault.setManager(address(manager));
        
        // In production, you would execute 'manager.setManageRoot(...)' here
        // to authorize the first batch of strategies.

        vm.stopBroadcast();

        // ---------------------------------------------------------
        // 5. Output Verification
        // ---------------------------------------------------------
        console.log("=== VEDA ARCTIC DEPLOYMENT COMPLETE ===");
        console.log("Lens (Frontend API):", address(lens));
        console.log("Teller (User Gate): ", address(teller));
        console.log("Vault (Holdings):   ", address(vault));
        console.log("Morpho Decoder:     ", address(morphoDecoder));
    }
}
