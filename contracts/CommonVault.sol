// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CommonVault is ERC4626, Ownable {
    // --- State Variables ---
    mapping(address => uint256) public pointsTotal;
    mapping(address => uint256) public lastUpdateBlock;
    mapping(address => uint256) public unbondingBalance;
    mapping(address => uint256) public unbondTimestamp;

    uint256 public constant UNBOND_DURATION = 24 hours;

    // --- Events ---
    event UnbondRequested(address indexed user, uint256 amount, uint256 burnedPoints);
    event FundsClaimed(address indexed user, uint256 amount);

    constructor(IERC20 asset) 
        ERC4626(asset) 
        ERC20("Common Vault USDC", "vUSDC") 
        Ownable(msg.sender) 
    {}

    // --- Internal Point Logic ---
    function _updatePoints(address user) internal {
        uint256 currentBalance = balanceOf(user);
        if (currentBalance > 0 && lastUpdateBlock[user] > 0) {
            uint256 blocksPassed = block.number - lastUpdateBlock[user];
            // Accrue points based on balance held over blocks
            pointsTotal[user] += (currentBalance * blocksPassed);
        }
        lastUpdateBlock[user] = block.number;
    }

    // --- Core Functions ---

    // Stage 1: Deposit (Fund enters Bonded state)
    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        _updatePoints(receiver);
        return shares;
    }

    // Stage 2: Request Unbond (Fund enters Unbonding state)
    function requestUnbond(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Common: Insufficient balance");
        _updatePoints(msg.sender);

        // Proportional Burn calculation
        uint256 totalShares = balanceOf(msg.sender);
        uint256 burnAmount = (amount * pointsTotal[msg.sender]) / totalShares;
        pointsTotal[msg.sender] -= burnAmount;
        
        _burn(msg.sender, amount);
        unbondingBalance[msg.sender] += amount;
        unbondTimestamp[msg.sender] = block.timestamp;

        emit UnbondRequested(msg.sender, amount, burnAmount);
    }

    // Stage 3 & 4: Claim (Fund moves from Unbonded state to Wallet)
    function withdrawUnbonded() external {
        require(unbondingBalance[msg.sender] > 0, "Common: No funds to claim");
        require(block.timestamp >= unbondTimestamp[msg.sender] + UNBOND_DURATION, "Common: Still unbonding");

        uint256 amount = unbondingBalance[msg.sender];
        unbondingBalance[msg.sender] = 0;
        
        IERC20(asset()).transfer(msg.sender, amount);
        emit FundsClaimed(msg.sender, amount);
    }

    // View helper for Frontend Tier Display
    function getWithdrawalFee(address user) public view returns (uint256) {
        uint256 pts = pointsTotal[user] / 1e18; // Normalized check
        if (pts >= 1000000) return 10; // Lvl 5
        if (pts >= 500000)  return 12; // Lvl 4
        if (pts >= 100000)  return 18; // Lvl 3
        if (pts >= 10000)   return 25; // Lvl 2
        return 35;                     // Lvl 1
    }
}
