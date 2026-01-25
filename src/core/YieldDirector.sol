// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface ISmartVault {
    function asset() external view returns (address);
    function pushToDirector(uint256 amount) external;
}

interface IAdapter {
    function deposit(uint256 amount) external returns (uint256);
    function setDirector(address newDirector) external;
}

contract YieldDirector is Ownable {
    using SafeERC20 for IERC20;

    address public adapter;

    event Rebalanced(address indexed vault, uint256 amount, address indexed adapter);
    event AdapterUpdated(address indexed oldAdapter, address indexed newAdapter);

    constructor() Ownable(msg.sender) {}

    function setAdapter(address _adapter) external onlyOwner {
        emit AdapterUpdated(adapter, _adapter);
        adapter = _adapter;
    }

    function rebalance(address vault) external onlyOwner {
        require(adapter != address(0), "No adapter set");

        IERC20 asset = IERC20(ISmartVault(vault).asset());
        uint256 vaultBal = asset.balanceOf(vault);
        
        if (vaultBal > 0) {
            ISmartVault(vault).pushToDirector(vaultBal);
        }

        uint256 myBal = asset.balanceOf(address(this));
        if (myBal > 0) {
            asset.forceApprove(adapter, myBal);
            IAdapter(adapter).deposit(myBal);
            emit Rebalanced(vault, myBal, adapter);
        }
    }
}
