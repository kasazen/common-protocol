// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {WorldIDHook} from "../hooks/WorldIDHook.sol";

contract AccountantWithRateProviders is Auth {
    ERC20 public immutable BASE_ASSET;
    WorldIDHook public immutable HOOK;
    
    uint256 public lastRate = 1e18;
    uint256 public performanceFeeBps = 2500;
    address public feeRecipient;
    address public teller; 
    bool public isPaused;

    mapping(address => uint256) public strategyAllocation; 
    mapping(address => uint256) public strategyApy;        
    
    mapping(address => uint256) public points;
    mapping(address => uint256) public lastInteraction;
    mapping(address => uint256) public loyaltyStart;

    event VedaPerformance(uint256 grossYield, uint256 vedaFee, uint256 netUserYield);

    constructor(address _owner, address _asset, address _hook, address _recipient) 
        Auth(_owner, Authority(address(0))) 
    {
        BASE_ASSET = ERC20(_asset);
        HOOK = WorldIDHook(_hook);
        feeRecipient = _recipient;
    }

    function setTeller(address _teller) external requiresAuth {
        teller = _teller;
    }

    function updateStrategy(address strategy, uint256 allocation, uint256 apy) external requiresAuth {
        strategyAllocation[strategy] = allocation;
        strategyApy[strategy] = apy;
    }

    function calculateGrossApy() public pure returns (uint256) {
        return 850; 
    }

    function recordInteraction(address user) external {
        require(msg.sender == teller || msg.sender == owner, "UNAUTHORIZED");
        lastInteraction[user] = block.timestamp;
        if (loyaltyStart[user] == 0) loyaltyStart[user] = block.timestamp;
        
        uint256 daysHeld = (block.timestamp - loyaltyStart[user]) / 1 days;
        uint256 loyaltyMultiplier = daysHeld > 30 ? 200 : 100; 
        points[user] += (10 ether * loyaltyMultiplier) / 100;
    }

    function getRateTiered(address user) public view returns (uint256) {
        if (isPaused) revert("PAUSED");
        return HOOK.isVerified(user) ? (lastRate * 120) / 100 : lastRate;
    }

    function updateRate(uint256 newRate) external requiresAuth {
        if (newRate > lastRate) {
            uint256 profit = newRate - lastRate;
            uint256 fee = (profit * performanceFeeBps) / 10000;
            newRate = newRate - fee;
        }
        lastRate = newRate;
    }

    function togglePause() external requiresAuth {
        isPaused = !isPaused;
    }
}
