// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IYieldAdapter} from "../interfaces/IYieldAdapter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
    function getReserveData(address asset) external view returns (uint256, uint128, uint128, uint128, uint128, uint128, uint40, address, address, address, address, uint8);
}

contract AaveAdapter is IYieldAdapter {
    using SafeERC20 for IERC20;
    
    // UPDATED: Uppercase naming for immutables (Standard Practice)
    address public immutable VAULT;
    IERC20 public immutable UNDERLYING;
    
    // Checksum fix included
    IAavePool public constant POOL = IAavePool(address(uint160(0x00319343f803Aa57497424647352358826F93f4439)));

    constructor(address _vault, address _asset) {
        VAULT = _vault;
        UNDERLYING = IERC20(_asset);
        UNDERLYING.approve(address(POOL), type(uint256).max);
    }

    function asset() external view returns (IERC20) { return UNDERLYING; }

    function getApr() external view returns (uint256) {
        (,,uint128 rate,,,,,,,,,) = POOL.getReserveData(address(UNDERLYING));
        return uint256(rate) / 1e23; 
    }

    function deposit(uint256 amount) external {
        require(msg.sender == VAULT, "Only Vault");
        UNDERLYING.safeTransferFrom(VAULT, address(this), amount);
        POOL.supply(address(UNDERLYING), amount, address(this), 0);
    }

    function withdraw(uint256 amount) external returns (uint256) {
        require(msg.sender == VAULT, "Only Vault");
        uint256 pulled = POOL.withdraw(address(UNDERLYING), amount, address(this));
        UNDERLYING.safeTransfer(VAULT, pulled);
        return pulled;
    }

    function withdrawAll() external returns (uint256) {
        require(msg.sender == VAULT, "Only Vault");
        uint256 pulled = POOL.withdraw(address(UNDERLYING), type(uint256).max, address(this));
        UNDERLYING.safeTransfer(VAULT, pulled);
        return pulled;
    }

    function totalAssets() external view returns (uint256) {
        return UNDERLYING.balanceOf(address(this)); 
    }
}
