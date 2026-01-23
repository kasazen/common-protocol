// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC4626, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {YieldDirector} from "./director/YieldDirector.sol";
import {IYieldAdapter} from "./interfaces/IYieldAdapter.sol";

contract MasterVault is ERC4626, Ownable {
    YieldDirector public director;
    IYieldAdapter public currentAdapter;
    uint256 public constant BUFFER_BPS = 1000; 

    event Rebalanced(address oldAdapter, address newAdapter, uint256 newApr);

    constructor(IERC20 _asset, address _director) 
        ERC4626(_asset) ERC20("Human Yield", "hYIELD") Ownable(msg.sender) 
    {
        director = YieldDirector(_director);
    }

    function totalAssets() public view override returns (uint256) {
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        uint256 active = address(currentAdapter) == address(0) ? 0 : currentAdapter.totalAssets();
        return idle + active;
    }

    function rebalance() external {
        (IYieldAdapter bestAdapter, uint256 bestApr) = director.getBestStrategy();
        
        // FIX: If we have NO strategy, take the best available one immediately
        if (address(currentAdapter) == address(0)) {
            if (address(bestAdapter) != address(0)) {
                _switchStrategy(bestAdapter, bestApr);
            }
            return;
        }

        uint256 currentApr = currentAdapter.getApr();
        if (address(bestAdapter) != address(currentAdapter) && director.shouldRebalance(currentApr, bestApr)) {
            _switchStrategy(bestAdapter, bestApr);
        }
    }

    function _switchStrategy(IYieldAdapter newAdapter, uint256 newApr) internal {
        if (address(currentAdapter) != address(0)) {
            currentAdapter.withdrawAll();
        }
        currentAdapter = newAdapter;
        _invest();
        emit Rebalanced(address(0), address(newAdapter), newApr);
    }

    function _invest() internal {
        if (address(currentAdapter) == address(0)) return;
        uint256 total = totalAssets();
        uint256 idle = IERC20(asset()).balanceOf(address(this));
        uint256 targetBuffer = (total * BUFFER_BPS) / 10000;

        if (idle > targetBuffer) {
            uint256 investable = idle - targetBuffer;
            IERC20(asset()).approve(address(currentAdapter), investable);
            currentAdapter.deposit(investable);
        }
    }

    function deposit(uint256 assets, address receiver) public override returns (uint256) {
        uint256 shares = super.deposit(assets, receiver);
        _invest();
        return shares;
    }
}
