// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStrategy} from "../interfaces/IStrategy.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract SafetyStrategy is IStrategy {
    using SafeERC20 for IERC20;
    address public immutable vault;
    IERC20 public immutable underlying;

    constructor(address _vault, address _asset) {
        vault = _vault;
        underlying = IERC20(_asset);
    }

    function asset() external view returns (IERC20) { return underlying; }

    function deposit(uint256 amount) external {
        require(msg.sender == vault, "Only vault");
        underlying.safeTransferFrom(vault, address(this), amount);
    }

    function withdraw(uint256 amount) external returns (uint256) {
        require(msg.sender == vault, "Only vault");
        underlying.safeTransfer(vault, amount);
        return amount;
    }

    function estimatedTotalAssets() external view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    function withdrawAll() external returns (uint256) {
        require(msg.sender == vault, "Only vault");
        uint256 balance = underlying.balanceOf(address(this));
        underlying.safeTransfer(vault, balance);
        return balance;
    }
}
