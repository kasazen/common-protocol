// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IYieldAdapter} from "../interfaces/IYieldAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockAdapter is IYieldAdapter {
    using SafeERC20 for IERC20;

    // FIXED: Screaming Snake Case for Immutables
    IERC20 public immutable ASSET;
    address public immutable VAULT;
    
    constructor(address _vault, address _asset) {
        VAULT = _vault;
        ASSET = IERC20(_asset);
    }
    
    function asset() external view returns (IERC20) { return ASSET; }
    
    function getApr() external pure returns (uint256) { return 500; } 
    
    function deposit(uint256 amount) external { 
        // FIXED: Use safeTransferFrom to silence warnings
        ASSET.safeTransferFrom(VAULT, address(this), amount);
    }

    function withdraw(uint256 amount) external returns (uint256) {
        // FIXED: Use safeTransfer
        ASSET.safeTransfer(VAULT, amount);
        return amount;
    }

    function withdrawAll() external returns (uint256) {
        uint256 bal = ASSET.balanceOf(address(this));
        ASSET.safeTransfer(VAULT, bal);
        return bal;
    }

    function totalAssets() external view returns (uint256) {
        return ASSET.balanceOf(address(this));
    }
}
