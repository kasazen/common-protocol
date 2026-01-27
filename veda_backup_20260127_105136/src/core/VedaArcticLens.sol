// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccountantWithRateProviders} from "./AccountantWithRateProviders.sol";
import {TellerWithMultiAssetSupport} from "./TellerWithMultiAssetSupport.sol";
import {BoringVault} from "../base/BoringVault.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract VedaArcticLens {
    struct Dashboard {
        // User Financials
        uint256 walletBalance;      // USDC in wallet
        uint256 vaultValueUsd;      // Value deposited in Veda
        
        // Yield Stack (The "Wealth Effect")
        uint256 grossApy;           // Base Protocol APY (Aave/Morpho)
        uint256 netApy;             // User's effective rate
        uint256 loyaltyMultiplier;  // 100 (1x), 200 (2x), 300 (3x)
        
        // Engagement
        uint256 fuelPoints;         // Total Veda Fuel
        bool isVerified;            // World ID Status
        
        // Safety & Solvency (Trust Layer)
        uint256 unlockTimer;        // Seconds until withdrawal is free
        uint256 liquidityBuffer;    // % of Vault assets sitting idle (Basis Points)
    }

    function getDashboard(address user, address vault, address accountant, address teller) 
        external view returns (Dashboard memory d) 
    {
        BoringVault v = BoringVault(payable(vault));
        AccountantWithRateProviders acc = AccountantWithRateProviders(accountant);
        TellerWithMultiAssetSupport tel = TellerWithMultiAssetSupport(teller);

        // 1. Balances
        d.walletBalance = v.asset().balanceOf(user);
        d.vaultValueUsd = v.convertToAssets(v.balanceOf(user));

        // 2. Yield Intelligence
        d.grossApy = acc.calculateGrossApy();
        d.netApy = acc.getRateTiered(user);
        
        // RETENTION HOOK: Show the user their specific Tier (Silver/Gold)
        d.loyaltyMultiplier = acc.getLoyaltyMultiplier(user);

        // 3. Engagement
        d.fuelPoints = acc.points(user);
        d.isVerified = acc.HOOK().isVerified(user);
        
        // 4. Safety & Solvency
        uint256 unlock = tel.depositTimestamp(user) + tel.SHARE_LOCK_PERIOD();
        d.unlockTimer = block.timestamp >= unlock ? 0 : unlock - block.timestamp;
        
        // SOLVENCY CHECK: Avoid division by zero if vault is empty
        uint256 totalAssets = v.totalAssets();
        if (totalAssets > 0) {
            // Calculate what % of assets are sitting as Idle USDC
            uint256 idleCash = v.asset().balanceOf(address(v));
            d.liquidityBuffer = (idleCash * 10000) / totalAssets;
        } else {
            d.liquidityBuffer = 10000; // 100% liquid if empty
        }
    }
}
