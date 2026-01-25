// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

contract DiscoveryV2 is Script {
    function run() external view {
        console.log("====== LIQUIDITY SCOUT REPORT ======");

        // 1. Velodrome V2 Factory (Standard Superchain Address)
        address VELO_FACTORY = 0xF1046053aa5682b4F9a81b5481394DA16BE5FF5a;
        
        // 2. Uniswap V3 Factory (Official World Chain Deployment)
        address UNI_FACTORY  = 0x7a5028BDa40e7B173C278C5342087826455ea25a;

        // 3. Uniswap Universal Router (Likely Candidate)
        address UNI_ROUTER   = 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD;

        // --- CHECKS ---

        if (VELO_FACTORY.code.length > 0) {
            console.log("VELODROME Factory Found at:", VELO_FACTORY);
        } else {
            console.log("VELODROME Factory NOT found.");
        }

        if (UNI_FACTORY.code.length > 0) {
            console.log("UNISWAP Factory Found at:", UNI_FACTORY);
        } else {
            console.log("UNISWAP Factory NOT found.");
        }

        if (UNI_ROUTER.code.length > 0) {
            console.log("UNISWAP Router Found at:", UNI_ROUTER);
        } else {
            console.log("UNISWAP Router NOT found.");
        }

        console.log("====== END REPORT ======");
    }
}
