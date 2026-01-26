// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccountantWithRateProviders} from "./AccountantWithRateProviders.sol";
import {TellerWithMultiAssetSupport} from "./TellerWithMultiAssetSupport.sol";
import {BoringVault} from "../base/BoringVault.sol";

contract VedaArcticLens {
    struct Dashboard {
        uint256 walletBalance;
        uint256 vaultValueUsd;
        uint256 grossApy;
        uint256 netApy;
        uint256 fuelPoints;
        bool isVerified;
        uint256 unlockTimer;
    }

    function getDashboard(address user, address vault, address accountant, address teller) 
        external view returns (Dashboard memory d) 
    {
        BoringVault v = BoringVault(payable(vault));
        AccountantWithRateProviders acc = AccountantWithRateProviders(accountant);
        TellerWithMultiAssetSupport tel = TellerWithMultiAssetSupport(teller);

        d.walletBalance = v.asset().balanceOf(user);
        d.vaultValueUsd = v.convertToAssets(v.balanceOf(user));
        d.grossApy = acc.calculateGrossApy();
        d.netApy = acc.getRateTiered(user);
        d.fuelPoints = acc.points(user);
        d.isVerified = acc.HOOK().isVerified(user);
        
        uint256 unlock = tel.depositTimestamp(user) + tel.SHARE_LOCK_PERIOD();
        d.unlockTimer = block.timestamp >= unlock ? 0 : unlock - block.timestamp;
    }
}
