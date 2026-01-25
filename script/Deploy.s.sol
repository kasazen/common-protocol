// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MasterVault} from "../src/MasterVault.sol";
import {YieldDirector} from "../src/director/YieldDirector.sol";
import {AaveAdapter} from "../src/adapters/AaveAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployVault is Script {
    // World Chain USDC Address
    address constant USDC = address(uint160(0x0079A02482A880bCE3F13e09Da970dC34db4CD24d1));

    function run() external {
        // CRITICAL FIX: explicit logging to prove who is signing
        address deployer = msg.sender;
        console.log("--------------------------------------------------");
        console.log("ACTUAL DEPLOYER ADDRESS:", deployer);
        console.log("--------------------------------------------------");

        // Start broadcasting with the account provided in the terminal (deployer)
        vm.startBroadcast(); 

        YieldDirector director = new YieldDirector();
        console.log("YieldDirector deployed at:", address(director));

        MasterVault vault = new MasterVault(IERC20(USDC), address(director));
        console.log("MasterVault deployed at:", address(vault));

        AaveAdapter aaveAdapter = new AaveAdapter(address(vault), USDC);
        console.log("AaveAdapter deployed at:", address(aaveAdapter));

        director.addAdapter(address(aaveAdapter));
        console.log("AaveAdapter wired to Director");

        vm.stopBroadcast();
    }
}
