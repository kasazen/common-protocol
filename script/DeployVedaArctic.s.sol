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
import {ERC20} from "solmate/tokens/ERC20.sol";

contract DeployVedaArctic is Script {
    function run() external {
        address usdcAddr = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1; 
        address aavePool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
        
        address mainOwner = msg.sender;
        address testWallet = address(0xDEAFBEEF); 

        vm.startBroadcast();

        WorldIDHook hook = new WorldIDHook(); 
        RevenueSplitter splitter = new RevenueSplitter(mainOwner, testWallet);
        VedaArcticLens lens = new VedaArcticLens();

        AccountantWithRateProviders accountant = new AccountantWithRateProviders(
            mainOwner, usdcAddr, address(hook), address(splitter)
        );

        BoringVault vault = new BoringVault(payable(mainOwner), "Veda Arctic USDC", "vUSDC", ERC20(usdcAddr));
        
        ManagerWithMerkleVerification manager = new ManagerWithMerkleVerification(
            mainOwner, address(vault)
        );

        TellerWithMultiAssetSupport teller = new TellerWithMultiAssetSupport(
            mainOwner, address(vault), address(accountant)
        );

        accountant.setTeller(address(teller));
        vault.setManager(address(manager));
        accountant.updateStrategy(aavePool, 10000, 450);

        vm.stopBroadcast();

        console.log("Lens Deployed at:", address(lens));
    }
}
