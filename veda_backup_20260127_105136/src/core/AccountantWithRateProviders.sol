// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {WorldIDHook} from "../hooks/WorldIDHook.sol";

contract AccountantWithRateProviders is Auth {
    // -----------------------------------------------------------------------
    // Immutable Storage
    // -----------------------------------------------------------------------
    ERC20 public immutable BASE_ASSET;
    WorldIDHook public immutable HOOK;

    // -----------------------------------------------------------------------
    // Protocol State
    // -----------------------------------------------------------------------
    uint256 public lastRate = 1e18;
    uint256 public performanceFeeBps = 2500; // 25%
    
    // SAFETY: Minimum 10% of funds must be "Idle" in the vault for withdrawals
    uint256 public constant MIN_IDLE_BPS = 1000; 

    address public feeRecipient;
    address public teller; 
    bool public isPaused;

    mapping(address => uint256) public strategyAllocation; 
    mapping(address => uint256) public strategyApy;        
    
    // Veda Fuel State
    mapping(address => uint256) public points;
    mapping(address => uint256) public lastInteraction;
    mapping(address => uint256) public loyaltyStart;

    // -----------------------------------------------------------------------
    // Events
    // -----------------------------------------------------------------------
    event VedaPerformance(uint256 grossYield, uint256 vedaFee, uint256 netUserYield);
    event RateUpdated(uint256 oldRate, uint256 newRate);

    constructor(address _owner, address _asset, address _hook, address _recipient) 
        Auth(_owner, Authority(address(0))) 
    {
        BASE_ASSET = ERC20(_asset);
        HOOK = WorldIDHook(_hook);
        feeRecipient = _recipient;
    }

    // -----------------------------------------------------------------------
    // Configuration Functions
    // -----------------------------------------------------------------------
    function setTeller(address _teller) external requiresAuth {
        teller = _teller;
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

    // -----------------------------------------------------------------------
    // View Functions (The "Lens" Data)
    // -----------------------------------------------------------------------
    function calculateGrossApy() public pure returns (uint256) {
        return 850; // Mock: In prod, iterate through strategyAllocation * strategyApy
    }

    function getRateTiered(address user) public view returns (uint256) {
        if (isPaused) revert("PAUSED");
        // Simple 20% yield boost for Verified Humans
        return HOOK.isVerified(user) ? (lastRate * 120) / 100 : lastRate;
    }

    // -----------------------------------------------------------------------
    // Veda Fuel Engine (Retention Logic)
    // -----------------------------------------------------------------------
    
    /**
     * @notice Determines the user's loyalty multiplier based on duration.
     * @param user The address to check.
     * @return multiplier The multiplier in basis points (100 = 1x, 300 = 3x).
     */
    function getLoyaltyMultiplier(address user) public view returns (uint256) {
        if (loyaltyStart[user] == 0) return 100; // Base 1x
        
        uint256 daysHeld = (block.timestamp - loyaltyStart[user]) / 1 days;

        // RETENTION LADDER:
        // 0-7 Days: "Honeymoon Phase" (3x) - Acquisition Hook
        // 30+ Days: "Silver Tier" (2x) - Retention Hook
        // 90+ Days: "Gold Tier" (3x) - Long Game
        if (daysHeld <= 7) return 300; 
        if (daysHeld > 90) return 300;
        if (daysHeld > 30) return 200;
        
        return 100; // Standard 1x for days 8-29
    }

    function recordInteraction(address user) external {
        require(msg.sender == teller || msg.sender == owner, "UNAUTHORIZED");
        
        lastInteraction[user] = block.timestamp;
        if (loyaltyStart[user] == 0) loyaltyStart[user] = block.timestamp;
        
        uint256 multiplier = getLoyaltyMultiplier(user);
        
        // Base Points: 10 ether (10 points) * Multiplier
        points[user] += (10 ether * multiplier) / 100;
    }
}
