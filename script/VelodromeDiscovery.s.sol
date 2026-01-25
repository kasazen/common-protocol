// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract VelodromeDiscovery is Script {
    function run() external view {
        console.log("--- VELODROME SCOUT REPORT ---");

        // 1. Target Addresses (World Chain)
        // Fixed Checksum:
        address ROUTER = 0x01D40099fCD87C018969B0e8D4aB1633Fb34763C; 
        
        address USDC = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        address WETH = 0x4200000000000000000000000000000000000006; 

        // 2. Check Router Existence
        if (ROUTER.code.length > 0) {
            console.log("Router FOUND at:", ROUTER);
            console.log("(This is the Universal Router)");
        } else {
            console.log("Router NOT found at Universal Address."); 
        }

        // 3. Check Token Existence
        if (USDC.code.length > 0) {
            console.log("USDC Contract FOUND");
        } else {
            console.log("USDC Contract MISSING");
        }

        if (WETH.code.length > 0) {
            console.log("WETH Contract FOUND");
        } else {
            console.log("WETH Contract MISSING");
        }

        console.log("--- END REPORT ---");
    }
}
