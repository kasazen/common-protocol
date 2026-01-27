// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {ERC4626} from "solmate/tokens/ERC4626.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

contract BoringVault is ERC4626, Auth {
    using SafeTransferLib for ERC20;

    address public manager;
    error BoringVault__OnlyManager();

    constructor(address _owner, string memory _name, string memory _symbol, ERC20 _asset) 
        ERC4626(_asset, _name, _symbol) 
        Auth(_owner, Authority(address(0))) 
    {}

    function manage(address target, bytes calldata data, uint256 value) external returns (bytes memory) {
        if (msg.sender != manager) revert BoringVault__OnlyManager();
        (bool success, bytes memory returnData) = target.call{value: value}(data);
        require(success, "BoringVault: Call Failed");
        return returnData;
    }

    function setManager(address _manager) external requiresAuth {
        manager = _manager;
    }

    function enter(address, ERC20, uint256, address to, uint256 shares) external requiresAuth {
        _mint(to, shares);
    }

    function exit(address to, ERC20 _asset, uint256 amount, address from, uint256 shares) external requiresAuth {
        _burn(from, shares);
        _asset.safeTransfer(to, amount);
    }

    function totalAssets() public view override returns (uint256) {
        return asset.balanceOf(address(this));
    }
}
