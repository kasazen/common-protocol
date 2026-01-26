// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Auth, Authority} from "solmate/auth/Auth.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import "../base/WorldChainConstants.sol";

contract AccountantWithRateProviders is Auth {
    using FixedPointMathLib for uint256;

    ERC20 public immutable baseAsset;
    bool public isPaused;

    error Accountant__Paused();

    constructor(address _owner, address _baseAsset) Auth(_owner, Authority(address(0))) {
        baseAsset = ERC20(_baseAsset);
    }

    function getRateSafe() external view returns (uint256) {
        if (isPaused) revert Accountant__Paused();
        return 1e18; 
    }
    
    function pause() external requiresAuth { isPaused = true; }
    function unpause() external requiresAuth { isPaused = false; }
}
