// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IAdapter {
    function deposit(uint256 amount) external;
}

contract YieldDirector is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    address public vault;
    address public adapter;

    constructor(address _asset) Ownable(msg.sender) {
        asset = IERC20(_asset);
    }

    // Wiring Configuration
    function setVault(address _vault) external onlyOwner {
        vault = _vault;
    }

    function setAdapter(address _adapter) external onlyOwner {
        adapter = _adapter;
        // Approve the adapter to spend our funds
        asset.approve(_adapter, type(uint256).max);
    }

    // The Action Button
    function rebalance() external {
        require(vault != address(0), "Vault not set");
        require(adapter != address(0), "Adapter not set");

        uint256 vaultBalance = asset.balanceOf(vault);
        
        if (vaultBalance > 0) {
            // 1. Pull funds from Vault (Vault must allow this)
            asset.safeTransferFrom(vault, address(this), vaultBalance);
            
            // 2. Push funds to Adapter
            asset.safeTransfer(adapter, vaultBalance);

            // 3. Execute Strategy
            IAdapter(adapter).deposit(vaultBalance);
        }
    }
}
