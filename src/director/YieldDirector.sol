// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IYieldAdapter} from "../interfaces/IYieldAdapter.sol";

contract YieldDirector is Ownable {
    IYieldAdapter[] public adapters;
    uint256 public upgradeThresholdBps = 50; 

    constructor() Ownable(msg.sender) {}

    function addAdapter(address _adapter) external onlyOwner {
        adapters.push(IYieldAdapter(_adapter));
    }

    function getBestStrategy() external view returns (IYieldAdapter bestAdapter, uint256 bestRate) {
        uint256 highestApr = 0;
        
        for (uint256 i = 0; i < adapters.length; i++) {
            try adapters[i].getApr() returns (uint256 apr) {
                // FIX: If bestAdapter is empty, take the first valid one we find
                if (apr > highestApr || address(bestAdapter) == address(0)) {
                    highestApr = apr;
                    bestAdapter = adapters[i];
                }
            } catch { continue; }
        }
        return (bestAdapter, highestApr);
    }
    
    function shouldRebalance(uint256 currentApr, uint256 newApr) external view returns (bool) {
        if (newApr <= currentApr) return false;
        return (newApr - currentApr) >= upgradeThresholdBps;
    }
}
