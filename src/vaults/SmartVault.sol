// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SmartVault is ERC4626, Ownable {
    using SafeERC20 for IERC20;

    address public strategist;

    event StrategistUpdated(address indexed newStrategist);
    event FundsPushed(address indexed to, uint256 amount);

    constructor(IERC20 asset, string memory name, string memory symbol) 
        ERC4626(asset) 
        ERC20(name, symbol) 
        Ownable(msg.sender) 
    {}

    function setStrategist(address _strategist, bool _active) external onlyOwner {
        strategist = _strategist;
        emit StrategistUpdated(_strategist);
    }

    function pushToDirector(uint256 amount) external {
        require(msg.sender == strategist, "Not Strategist");
        IERC20(asset()).safeTransfer(strategist, amount);
        emit FundsPushed(strategist, amount);
    }
}
