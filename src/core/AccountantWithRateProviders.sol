// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import "../hooks/WorldIDHook.sol";

contract AccountantWithRateProviders is Auth {
    ERC20 public immutable BASE_ASSET;
    WorldIDHook public immutable HOOK;
    address public immutable ORACLE;
    
    uint256 public lastRate = 1e18;
    uint256 public performanceFeeBps = 2500;
    address public feeRecipient;
    bool public isPaused;

    error Accountant__Paused();

    constructor(address _owner, address _asset, address _hook, address _recipient, address _oracle) 
        Auth(_owner, Authority(address(0))) 
    {
        BASE_ASSET = ERC20(_asset);
        HOOK = WorldIDHook(_hook);
        feeRecipient = _recipient;
        ORACLE = _oracle;
    }

    function getRateTiered(address user) public view returns (uint256) {
        if (isPaused) revert Accountant__Paused();
        bool isVerified = HOOK.isVerified(user);
        return isVerified ? (lastRate * 120) / 100 : lastRate;
    }

    function togglePause() external requiresAuth {
        isPaused = !isPaused;
    }

    function updateRate(uint256 newRate) external requiresAuth {
        if (newRate > lastRate) {
            uint256 profit = newRate - lastRate;
            uint256 fee = (profit * performanceFeeBps) / 10000;
            newRate = newRate - fee;
        }
        lastRate = newRate;
    }
}
