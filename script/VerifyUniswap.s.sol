// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

// Minimal interface to verify the router works
interface IUniswapRouter {
    function factory() external view returns (address);
}

contract VerifyUniswap is Script {
    function run() external view {
        console.log("====== UNISWAP V3 VERIFICATION (WORLD CHAIN) ======");

        // OFFICIAL ADDRESSES (Source: Uniswap Docs for Chain 480)
        address FACTORY       = 0x7a5028BDa40e7B173C278C5342087826455ea25a;
        address SWAP_ROUTER02 = 0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6;
        address QUOTER_V2     = 0x10158D43e6cc414deE1Bd1eB0EfC6a5cBCfF244c;
        address WETH          = 0x4200000000000000000000000000000000000006;
        
        // 1. Verify Factory
        if (FACTORY.code.length > 0) {
            console.log("Factory Found at:", FACTORY);
        } else {
            console.log("Factory MISSING (Critical Error)");
        }

        // 2. Verify Router
        if (SWAP_ROUTER02.code.length > 0) {
            console.log("SwapRouter02 Found at:", SWAP_ROUTER02);
            
            // 3. Handshake Check: Does Router know the Factory?
            try IUniswapRouter(SWAP_ROUTER02).factory() returns (address routerFactory) {
                if (routerFactory == FACTORY) {
                    console.log("Router <-> Factory Link: CONFIRMED");
                } else {
                    console.log("Router linked to WRONG Factory:", routerFactory);
                }
            } catch {
                console.log("Router handshake failed (Interface mismatch?)");
            }

        } else {
            console.log("SwapRouter02 MISSING (Critical Error)");
        }

        // 4. Verify Quoter
        if (QUOTER_V2.code.length > 0) {
            console.log("QuoterV2 Found at:", QUOTER_V2);
        } else {
            console.log("QuoterV2 MISSING");
        }

        console.log("====== END REPORT ======");
    }
}
