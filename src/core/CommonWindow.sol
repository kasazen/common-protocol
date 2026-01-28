// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CommonRates} from "./CommonRates.sol";
import {CommonGate} from "./CommonGate.sol";
import {BoringVault} from "../base/BoringVault.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract CommonWindow {
    struct Dashboard {
        uint256 walletBalance;
        uint256 vaultValueUsd;
        uint256 grossApy;
        uint256 netApy;
        uint256 loyaltyMultiplier;
        uint256 fuelPoints;
        bool isVerified;
        uint256 unlockTimer;
        uint256 liquidityBuffer;
    }

    function getDashboard(address user, address vault, address rates, address gate) 
        external view returns (Dashboard memory d) 
    {
        BoringVault v = BoringVault(payable(vault));
        CommonRates acc = CommonRates(rates);
        CommonGate tel = CommonGate(gate);

        d.walletBalance = v.asset().balanceOf(user);
        d.vaultValueUsd = v.convertToAssets(v.balanceOf(user));
        d.grossApy = acc.calculateGrossApy();
        d.netApy = acc.getRateTiered(user);
        d.loyaltyMultiplier = acc.getLoyaltyMultiplier(user);
        d.fuelPoints = acc.points(user);
        d.isVerified = acc.HOOK().isVerified(user);
        
        uint256 unlock = tel.depositTimestamp(user) + tel.SHARE_LOCK_PERIOD();
        d.unlockTimer = block.timestamp >= unlock ? 0 : unlock - block.timestamp;
        
        uint256 totalAssets = v.totalAssets();
        if (totalAssets > 0) {
            uint256 idleCash = v.asset().balanceOf(address(v));
            d.liquidityBuffer = (idleCash * 10000) / totalAssets;
        } else {
            d.liquidityBuffer = 10000;
        }
    }
}
