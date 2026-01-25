// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Interfaces to read state variables
interface IDirector {
    function vault() external view returns (address);
    function adapter() external view returns (address);
    function owner() external view returns (address);
}

interface IVault {
    function director() external view returns (address);
    function asset() external view returns (address);
    function owner() external view returns (address);
}

contract IntegrityCheck is Script {
    function run() external view {
        console.log("--- CONFIGURATION INTEGRITY CHECK ---");

        // 1. THE ASSUMED ADDRESSES (From Deployment Logs)
        address ASSUMED_DIRECTOR = 0x07B9B16f887bc1C66C204dE544F249Bc819911Dc;
        address ASSUMED_VAULT    = 0xB8AB1d5ee8828Ed201ae598ec3DF92632CEA8D67;
        address ASSUMED_ADAPTER  = 0x0d1aF06802659037e8C79a93717A2cb80bC52251;
        address USDC             = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;

        console.log("Checking Director:", ASSUMED_DIRECTOR);
        console.log("Checking Vault:   ", ASSUMED_VAULT);

        // 2. VERIFY DIRECTOR -> VAULT CONNECTION
        try IDirector(ASSUMED_DIRECTOR).vault() returns (address actualVault) {
            if (actualVault == ASSUMED_VAULT) {
                console.log("[PASS] Director points to correct Vault.");
            } else {
                console.log("[FAIL] Director points to WRONG Vault:", actualVault);
            }
        } catch {
            console.log("[FAIL] Could not read Director.vault (Wrong Address?)");
        }

        // 3. VERIFY VAULT -> DIRECTOR CONNECTION
        try IVault(ASSUMED_VAULT).director() returns (address actualDirector) {
            if (actualDirector == ASSUMED_DIRECTOR) {
                console.log("[PASS] Vault points to correct Director.");
            } else {
                console.log("[FAIL] Vault points to WRONG Director:", actualDirector);
            }
        } catch {
            console.log("[FAIL] Could not read Vault.director (Wrong Address?)");
        }

        // 4. VERIFY ADAPTER CONNECTION
        try IDirector(ASSUMED_DIRECTOR).adapter() returns (address actualAdapter) {
            if (actualAdapter == ASSUMED_ADAPTER) {
                console.log("[PASS] Director points to correct Adapter.");
            } else {
                console.log("[FAIL] Director points to WRONG Adapter:", actualAdapter);
            }
        } catch {
            console.log("[FAIL] Could not read Director.adapter");
        }

        // 5. CRITICAL: CHECK ALLOWANCE (The usual suspect for reverts)
        uint256 allowance = IERC20(USDC).allowance(ASSUMED_VAULT, ASSUMED_DIRECTOR);
        console.log("Vault -> Director USDC Allowance:", allowance);

        if (allowance > 1000000000) {
            console.log("[PASS] Director has permission to spend Vault funds.");
        } else {
            console.log("[FAIL] ALLOWANCE IS ZERO. Director cannot pull funds.");
            console.log("       This causes the 'Execution Reverted' error.");
        }

        // 6. CHECK VAULT BALANCE
        uint256 vaultBal = IERC20(USDC).balanceOf(ASSUMED_VAULT);
        console.log("Vault USDC Balance:", vaultBal);
        if (vaultBal > 0) {
            console.log("[PASS] Vault has funds to invest.");
        } else {
            console.log("[FAIL] Vault is empty. Nothing to rebalance.");
        }

        console.log("--- END CHECK ---");
    }
}
