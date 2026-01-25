// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SystemDiagnosis is Script {
    function run() external view {
        console.log("====== SYSTEM DIAGNOSTIC REPORT ======");

        // 1. Setup Addresses (From your logs)
        address USDC     = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        address VAULT    = 0x242b3A6aA3362B76bA13fe2580f0B2fDD8ddAb0C; // From your cast send
        address DIRECTOR = 0x56908D0865806ca95791dfeD74712152193c0ec7;
        address ADAPTER  = 0x6aceAeADb7f28E158BDD58D028e8C5b12378e649; // Uniswap Adapter

        IERC20 usdc = IERC20(USDC);

        // 2. Check Balances (Where is the money?)
        uint256 vaultBal    = usdc.balanceOf(VAULT);
        uint256 directorBal = usdc.balanceOf(DIRECTOR);
        uint256 adapterBal  = usdc.balanceOf(ADAPTER);

        console.log("--- BALANCES ---");
        console.log("Vault Holds:   ", vaultBal);
        console.log("Director Holds:", directorBal);
        console.log("Adapter Holds: ", adapterBal);

        // 3. Check Allowances (Can the money move?)
        // Can Director take from Vault?
        uint256 vaultToDirector = usdc.allowance(VAULT, DIRECTOR);
        console.log("--- PERMISSIONS ---");
        console.log("Vault -> Director Allowance:", vaultToDirector);

        // Can Adapter take from Director?
        uint256 directorToAdapter = usdc.allowance(DIRECTOR, ADAPTER);
        console.log("Director -> Adapter Allowance:", directorToAdapter);

        // 4. Analysis
        if (vaultBal > 0 && directorBal == 0 && vaultToDirector == 0) {
            console.log(">>> DIAGNOSIS: Money is stuck in Vault. Director has no permission to pull it.");
        } else if (directorBal > 0 && directorToAdapter == 0) {
            console.log(">>> DIAGNOSIS: Money is in Director, but Adapter cannot pull it (Missing Approval).");
        } else if (adapterBal > 0) {
            console.log(">>> DIAGNOSIS: Money is already in Adapter! (Did the trade already happen?)");
        } else {
            console.log(">>> DIAGNOSIS: Check balances above.");
        }

        console.log("==================================");
    }
}
