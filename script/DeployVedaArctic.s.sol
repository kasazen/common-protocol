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
        address usdcAddr = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        address morphoBlueAddr = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;
        
        vm.startBroadcast();
        address mainOwner = msg.sender;
        address partnerWallet = address(0xDEAFBEEF); 

        WorldIDHook hook = new WorldIDHook();
        RevenueSplitter splitter = new RevenueSplitter(mainOwner, partnerWallet);
        VedaArcticLens lens = new VedaArcticLens();

        AccountantWithRateProviders accountant = new AccountantWithRateProviders(
            mainOwner, usdcAddr, address(hook), address(splitter)
        );

        BoringVault vault = new BoringVault(payable(mainOwner), "Veda Arctic USDC", "vUSDC", ERC20(usdcAddr));
        ManagerWithMerkleVerification manager = new ManagerWithMerkleVerification(mainOwner, address(vault));
        TellerWithMultiAssetSupport teller = new TellerWithMultiAssetSupport(mainOwner, address(vault), address(accountant));
        MorphoBlueDecoder morphoDecoder = new MorphoBlueDecoder(morphoBlueAddr, usdcAddr);

        accountant.setTeller(address(teller));
        vault.setManager(address(manager));
        vm.stopBroadcast();

        console.log("=== VEDA ARCTIC DEPLOYED ===");
        console.log("Vault:", address(vault));
        console.log("Lens:", address(lens));
        console.log("Manager:", address(manager));
    }
}
