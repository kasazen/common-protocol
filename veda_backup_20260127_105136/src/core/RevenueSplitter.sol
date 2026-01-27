// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract RevenueSplitter {
    using SafeTransferLib for ERC20;

    address public immutable PARTNER_MAIN;
    address public immutable PARTNER_TEST;
    
    constructor(address _main, address _test) {
        PARTNER_MAIN = _main;
        PARTNER_TEST = _test;
    }

    function claimFees(ERC20 asset) external {
        uint256 balance = asset.balanceOf(address(this));
        uint256 half = balance / 2;
        asset.safeTransfer(PARTNER_MAIN, half);
        asset.safeTransfer(PARTNER_TEST, asset.balanceOf(address(this)));
    }
}
