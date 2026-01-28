// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {BoringVault} from "../src/base/BoringVault.sol";
import {CommonStrategy} from "../src/core/CommonStrategy.sol";
import {CommonGate} from "../src/core/CommonGate.sol";
import {CommonRates} from "../src/core/CommonRates.sol";
import {RevenueSplitter} from "../src/core/RevenueSplitter.sol";
import {CommonWindow} from "../src/core/CommonWindow.sol";
import {WorldIDHook} from "../src/hooks/WorldIDHook.sol";
import {MorphoBlueDecoder} from "../src/decoders/MorphoBlueDecoder.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract DeployCommonArctic is Script {
    function run() external {
        // ---------------------------------------------------------
        // 1. Configuration (World Chain Mainnet Constants)
        // ---------------------------------------------------------
        address usdcAddr = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        address morphoBlueAddr = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;

        // ---------------------------------------------------------
        // 2. Strict Ownership (Hardcoded Security)
        // ---------------------------------------------------------
        // We explicitly define the owner to prevent accidental assignment to a hot wallet
        address mainOwner = 0xc387A2EB7878ef61C032226B21f2A596E727564C;
        address partnerWallet = address(0xDEAFBEEF); // Replace with real partner if needed

        // ---------------------------------------------------------
        // 3. Deploy Infrastructure
        // ---------------------------------------------------------
        vm.startBroadcast();

        // Core Components
        WorldIDHook hook = new WorldIDHook();
        RevenueSplitter splitter = new RevenueSplitter(mainOwner, partnerWallet);
        CommonWindow window = new CommonWindow();

        // The Brain (Rates) - Locked to mainOwner
        CommonRates rates = new CommonRates(
            mainOwner, usdcAddr, address(hook), address(splitter)
        );

        // The Vault (Asset Container) - Locked to mainOwner
        BoringVault vault = new BoringVault(payable(mainOwner), "Common USDC", "vUSDC", ERC20(usdcAddr));

        // The Strategy (Security Layer) - Locked to mainOwner
        CommonStrategy strategy = new CommonStrategy(
            mainOwner, address(vault)
        );

        // The Gate (Human Gate) - Locked to mainOwner
        CommonGate gate = new CommonGate(
            mainOwner, address(vault), address(rates)
        );

        // ---------------------------------------------------------
        // 4. Safety Equipment (Decoders)
        // ---------------------------------------------------------
        MorphoBlueDecoder morphoDecoder = new MorphoBlueDecoder(morphoBlueAddr, usdcAddr);

        // ---------------------------------------------------------
        // 5. Wiring & Permissions
        // ---------------------------------------------------------
        // Note: Since 'mainOwner' is 0xc387..., and we are likely deploying from 
        // the same address, we can configure these. If deploying from a different 
        // gas wallet, these calls might revert or need to be done by the owner later.
        
        // We assume msg.sender (deployer) == mainOwner for initial setup
        if (msg.sender == mainOwner) {
            rates.setGate(address(gate));
            vault.setStrategy(address(strategy));
        } else {
            console.log("WARNING: Deployer is not Owner. You must manually call setGate/setStrategy from 0xc387...");
        }

        vm.stopBroadcast();

        // ---------------------------------------------------------
        // 6. Output Verification
        // ---------------------------------------------------------
        console.log("=== VEDA ARCTIC DEPLOYMENT COMPLETE ===");
        console.log("OWNER LOCKED TO:    ", mainOwner);
        console.log("Window (Frontend):    ", address(window));
        console.log("Gate (User Gate): ", address(gate));
        console.log("Vault (Holdings):   ", address(vault));
        console.log("Strategy (Brain):    ", address(strategy));
        console.log("Morpho Decoder:     ", address(morphoDecoder));
    }
}
