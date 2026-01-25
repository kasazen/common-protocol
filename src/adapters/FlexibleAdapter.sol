// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract FlexibleAdapter is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable asset;
    IERC4626 public immutable targetVault; 
    address public director;

    constructor(address _asset, address _targetVault, address _director) Ownable(msg.sender) {
        asset = IERC20(_asset);
        targetVault = IERC4626(_targetVault);
        director = _director;
    }

    modifier onlyDirector() {
        require(msg.sender == director, "Not Director");
        _;
    }

    function setDirector(address _newDirector) external onlyOwner {
        director = _newDirector;
    }

    function deposit(uint256 amount) external onlyDirector returns (uint256) {
        asset.safeTransferFrom(msg.sender, address(this), amount);
        asset.forceApprove(address(targetVault), amount);
        return targetVault.deposit(amount, address(this));
    }

    function withdraw(uint256 amount) external onlyDirector returns (uint256) {
        return targetVault.withdraw(amount, director, address(this));
    }

    function totalAssets() external view returns (uint256) {
        return targetVault.convertToAssets(targetVault.balanceOf(address(this)));
    }
}
