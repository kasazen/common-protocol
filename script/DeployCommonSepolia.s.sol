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
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract DeployCommonSepolia is Script {
    function run() external {
        // ---------------------------------------------------------
        // 1. STRICT OWNERSHIP (Your Cold Wallet)
        // ---------------------------------------------------------
        address mainOwner = 0xc387A2EB7878ef61C032226B21f2A596E727564C;
        address partnerWallet = address(0xDEAFBEEF); 

        vm.startBroadcast();

        // ---------------------------------------------------------
        // 2. TESTNET MOCKS (The "Fake" Reality)
        // ---------------------------------------------------------
        // We deploy a fresh "Mock USDC" so the Vault has something to hold.
        MockERC20 mockUsdc = new MockERC20("Mock USDC", "mUSDC", 6);
        
        // MINT 100,000 TEST TOKENS TO YOU
        mockUsdc.mint(mainOwner, 100_000e6);
        console.log("MINTED 100k mUSDC TO:", mainOwner);

        // Placeholder for Morpho (since it doesn't exist here, we use a dummy address)
        address mockMorpho = address(0xDEAD);

        // ---------------------------------------------------------
        // 3. DEPLOY INFRASTRUCTURE
        // ---------------------------------------------------------
        WorldIDHook hook = new WorldIDHook();
        RevenueSplitter splitter = new RevenueSplitter(mainOwner, partnerWallet);
        CommonWindow window = new CommonWindow();

        CommonRates rates = new CommonRates(
            mainOwner, address(mockUsdc), address(hook), address(splitter)
        );

        BoringVault vault = new BoringVault(payable(mainOwner), "Common Sepolia", "vTEST", mockUsdc);

        CommonStrategy strategy = new CommonStrategy(
            mainOwner, address(vault)
        );

        CommonGate gate = new CommonGate(
            mainOwner, address(vault), address(rates)
        );

        MorphoBlueDecoder morphoDecoder = new MorphoBlueDecoder(mockMorpho, address(mockUsdc));

        // ---------------------------------------------------------
        // 4. WIRING
        // ---------------------------------------------------------
        if (msg.sender == mainOwner) {
            rates.setGate(address(gate));
            vault.setStrategy(address(strategy));
        }

        vm.stopBroadcast();

        console.log("=== VEDA SEPOLIA DEPLOYMENT COMPLETE ===");
        console.log("OWNER:      ", mainOwner);
        console.log("Mock USDC:  ", address(mockUsdc));
        console.log("Vault:      ", address(vault));
        console.log("Strategy:    ", address(strategy));
        console.log("Window:       ", address(window));
    }
}
