// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CommonVault is ERC4626, Ownable {
    struct UnbondRequest {
        uint256 amount;
        uint256 unlockTimestamp;
        bool claimed;
    }

    mapping(address => uint256) public pointsTotal;
    mapping(address => uint256) public lastUpdateBlock;
    
    // --- NEW: Verification State ---
    mapping(address => bool) public isVerified;
    // Store multiple requests per user
    mapping(address => UnbondRequest[]) public unbondRequests;

    uint256 public constant UNBOND_DURATION = 24 hours;

    event UnbondRequested(address indexed user, uint256 amount, uint256 unlockTimestamp);
    event FundsClaimed(address indexed user, uint256 amount, uint256 index);

    constructor(IERC20 asset) ERC4626(asset) ERC20("Common Vault USDC", "vUSDC") Ownable(msg.sender) {}

    // --- NEW: Verification Logic ---
    modifier onlyVerified() {
        require(isVerified[msg.sender], "Common: Not Verified");
        _;
    }

    function setVerification(address user, bool status) external onlyOwner {
        isVerified[user] = status;
    }

    // --- FIXED: Restored missing function header below ---
    function _updatePoints(address user) internal {
        uint256 currentBalance = balanceOf(user);
        if (currentBalance > 0 && lastUpdateBlock[user] > 0) {
            uint256 blocksPassed = block.number - lastUpdateBlock[user];
            pointsTotal[user] += (currentBalance * blocksPassed);
        }
        lastUpdateBlock[user] = block.number;
    }

    // --- UPDATED: Now checks onlyVerified ---
    function deposit(uint256 assets, address receiver) public override onlyVerified returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        _updatePoints(receiver);
        return shares;
    }

    function requestUnbond(uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Common: Insufficient balance");
        _updatePoints(msg.sender);

        uint256 totalShares = balanceOf(msg.sender);
        // Safety check to avoid division by zero if totalShares is somehow 0
        if (totalShares > 0) {
            uint256 burnAmount = (amount * pointsTotal[msg.sender]) / totalShares;
            pointsTotal[msg.sender] -= burnAmount;
        }
        
        _burn(msg.sender, amount);
        
        // Push a new independent request
        unbondRequests[msg.sender].push(UnbondRequest({
            amount: amount,
            unlockTimestamp: block.timestamp + UNBOND_DURATION,
            claimed: false
        }));

        emit UnbondRequested(msg.sender, amount, block.timestamp + UNBOND_DURATION);
    }

    // Now requires an index to claim a specific matured chunk
    function withdrawUnbonded(uint256 index) external {
        require(index < unbondRequests[msg.sender].length, "Common: Invalid index");
        UnbondRequest storage request = unbondRequests[msg.sender][index];
        
        require(!request.claimed, "Common: Already claimed");
        require(block.timestamp >= request.unlockTimestamp, "Common: Still unbonding");

        request.claimed = true;
        IERC20(asset()).transfer(msg.sender, request.amount);
        
        emit FundsClaimed(msg.sender, request.amount, index);
    }

    function getUnbondRequests(address user) external view returns (UnbondRequest[] memory) {
        return unbondRequests[user];
    }

    function getWithdrawalFee(address user) public view returns (uint256) {
        uint256 pts = pointsTotal[user] / 1e18;
        if (pts >= 1000000) return 10;
        if (pts >= 500000)  return 12;
        if (pts >= 100000)  return 18;
        if (pts >= 10000)   return 25;
        return 35;
    }
}