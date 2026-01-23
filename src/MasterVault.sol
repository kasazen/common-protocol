// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC4626} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";

contract MasterVault is ERC4626, Ownable, ReentrancyGuard {
    IStrategy public currentStrategy;
    uint256 public constant BUFFER_BPS = 1000; // 10%

    constructor(IERC20 _asset, string memory _name, string memory _symbol) 
        ERC4626(_asset) ERC20(_name, _symbol) Ownable(msg.sender) {}

    function totalAssets() public view override returns (uint256) {
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        uint256 inStrategy = address(currentStrategy) == address(0) ? 0 : currentStrategy.estimatedTotalAssets();
        return idle + inStrategy;
    }

    function setStrategy(address _strategy) external onlyOwner {
        if (address(currentStrategy) != address(0)) {
            currentStrategy.withdrawAll();
        }
        currentStrategy = IStrategy(_strategy);
        IERC20(asset()).approve(_strategy, type(uint256).max);
    }

    function invest() external onlyOwner nonReentrant {
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        uint256 total = totalAssets();
        uint256 targetBuffer = (total * BUFFER_BPS) / 10000;
        
        if (idle > targetBuffer) {
            uint256 toInvest = idle - targetBuffer;
            currentStrategy.deposit(toInvest);
        }
    }
}
