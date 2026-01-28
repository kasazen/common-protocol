// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {WorldIDHook} from "../hooks/WorldIDHook.sol";

contract CommonRates is Auth {
    ERC20 public immutable BASE_ASSET;
    WorldIDHook public immutable HOOK;

    uint256 public lastRate = 1e18;
    uint256 public performanceFeeBps = 2500; // 25%
    
    // SAFETY: Minimum 10% of funds must be Idle in the vault for withdrawals
    uint256 public constant MIN_IDLE_BPS = 1000;

    address public feeRecipient;
    address public gate; 
    bool public isPaused;

    mapping(address => uint256) public strategyAllocation; 
    mapping(address => uint256) public strategyApy;
    
    // Common Fuel State
    mapping(address => uint256) public points;
    mapping(address => uint256) public lastInteraction;
    mapping(address => uint256) public loyaltyStart;

    event CommonPerformance(uint256 grossYield, uint256 vedaFee, uint256 netUserYield);
    event RateUpdated(uint256 oldRate, uint256 newRate);

    constructor(address _owner, address _asset, address _hook, address _recipient) 
        Auth(_owner, Authority(address(0))) 
    {
        BASE_ASSET = ERC20(_asset);
        HOOK = WorldIDHook(_hook);
        feeRecipient = _recipient;
    }

    function setGate(address _gate) external requiresAuth {
        gate = _gate;
    }

    function updateStrategy(address strategy, uint256 allocation, uint256 apy) external requiresAuth {
        strategyAllocation[strategy] = allocation;
        strategyApy[strategy] = apy;
    }

    function updateRate(uint256 newRate) external requiresAuth {
        if (newRate > lastRate) {
            uint256 profit = newRate - lastRate;
            uint256 fee = (profit * performanceFeeBps) / 10000;
            newRate = newRate - fee;
        }
        emit RateUpdated(lastRate, newRate);
        lastRate = newRate;
    }

    function togglePause() external requiresAuth {
        isPaused = !isPaused;
    }

    function calculateGrossApy() public pure returns (uint256) {
        return 850; // Mock
    }

    function getRateTiered(address user) public view returns (uint256) {
        if (isPaused) revert("PAUSED");
        return HOOK.isVerified(user) ? (lastRate * 120) / 100 : lastRate;
    }

    /**
     * @notice Determines the user loyalty multiplier based on duration.
     */
    function getLoyaltyMultiplier(address user) public view returns (uint256) {
        if (loyaltyStart[user] == 0) return 100;
        uint256 daysHeld = (block.timestamp - loyaltyStart[user]) / 1 days;

        // RETENTION LADDER:
        if (daysHeld <= 7) return 300; // Honeymoon (3x)
        if (daysHeld > 90) return 300; // Gold (3x)
        if (daysHeld > 30) return 200; // Silver (2x)
        return 100;
    }

    function recordInteraction(address user) external {
        require(msg.sender == gate || msg.sender == owner, "UNAUTHORIZED");
        lastInteraction[user] = block.timestamp;
        if (loyaltyStart[user] == 0) loyaltyStart[user] = block.timestamp;
        uint256 multiplier = getLoyaltyMultiplier(user);
        points[user] += (10 ether * multiplier) / 100;
    }
}
