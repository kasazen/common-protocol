// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC4626} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract HumanYieldVault is ERC4626, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 public constant BUFFER_PERCENT = 10; 
    uint256 public totalInvested;

    // TRUST EVENTS: Creates an immutable on-chain audit trail
    event FundsInvested(uint256 amount);
    event FundsRepaid(uint256 principalRepaid, uint256 profitRealized);
    event LossReported(uint256 amount);

    constructor(IERC20 _asset) 
        ERC4626(_asset) 
        ERC20("Human Yield Shares", "hYIELD") 
        Ownable(msg.sender) 
    {}

    function totalAssets() public view override returns (uint256) {
        return IERC20(asset()).balanceOf(address(this)) + totalInvested;
    }

    /**
     * @dev 1. INVEST: Moves funds to the Manager (You) to deploy into Strategy.
     * STRICT: Enforces 10% liquidity buffer.
     */
    function invest(uint256 amount) external onlyOwner nonReentrant {
        uint256 assets = totalAssets();
        uint256 currentCash = IERC20(asset()).balanceOf(address(this));
        
        // Safety Check 1: Do we have the cash?
        require(amount <= currentCash, "Insufficient liquid cash");

        // Safety Check 2: Does this violate the 10% buffer?
        uint256 maxTotalInvestment = (assets * (100 - BUFFER_PERCENT)) / 100;
        require(totalInvested + amount <= maxTotalInvestment, "Buffer violation: Must keep 10% liquid");
        
        // Update State
        totalInvested += amount;
        emit FundsInvested(amount);
        
        // Move funds to Owner (Manager)
        IERC20(asset()).safeTransfer(msg.sender, amount);
    }

    /**
     * @dev 2. REPAY: The Trust Mechanism.
     * This allows you to return funds + profit. It Atomicially updates accounting
     * AND pulls the money back in one transaction. No "fake" updates allowed.
     */
    function repay(uint256 amount) external onlyOwner nonReentrant {
        // Calculate how much is principal vs profit
        uint256 principal = (amount > totalInvested) ? totalInvested : amount;
        uint256 profit = amount - principal;

        // Pull the tokens from Owner back to Vault
        // Note: You must 'approve' the vault to spend your USDC before calling this
        IERC20(asset()).safeTransferFrom(msg.sender, address(this), amount);

        totalInvested -= principal;
        emit FundsRepaid(principal, profit);
    }

    /**
     * @dev 3. LOSS REPORTING: The "Honesty" Function.
     * Only used if a strategy fails. Instead of "Withdrawing", this acknowledges 
     * that money is gone, updating the share price accurately.
     */
    function reportLoss(uint256 amount) external onlyOwner {
        require(amount <= totalInvested, "Cannot report loss larger than investment");
        totalInvested -= amount;
        emit LossReported(amount);
    }
}