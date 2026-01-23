// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
    function asset() external view returns (IERC20);
    function estimatedTotalAssets() external view returns (uint256);
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external returns (uint256 actualWithdrawn);
    function withdrawAll() external returns (uint256 totalPulled);
}
