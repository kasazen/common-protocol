// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {BoringVault} from "../base/BoringVault.sol";
import "../hooks/WorldIDHook.sol";

contract TellerWithMultiAssetSupport is Auth {
    using SafeTransferLib for ERC20;

    BoringVault public immutable vault;
    WorldIDHook public immutable hook;
    
    uint256 public constant SHARE_LOCK_PERIOD = 1 days;
    mapping(address => uint256) public shareUnlockTime;

    error Teller__SharesLocked();

    constructor(address _owner, address _vault, address _hook) 
        Auth(_owner, Authority(address(0))) 
    {
        vault = BoringVault(payable(_vault));
        hook = WorldIDHook(_hook);
    }
    function deposit(ERC20 asset, uint256 amount, uint256 minShares) external returns (uint256 shares) {
        hook.beforeDeposit(msg.sender, amount);
        asset.safeTransferFrom(msg.sender, address(vault), amount);
        shares = amount; 
        vault.enter(msg.sender, asset, amount, msg.sender, shares);
        shareUnlockTime[msg.sender] = block.timestamp + SHARE_LOCK_PERIOD;
    }

    function withdraw(uint256 shares, uint256 minAssets) external {
        if (block.timestamp < shareUnlockTime[msg.sender]) revert Teller__SharesLocked();
        ERC20 asset = ERC20(vault.asset());
        vault.exit(msg.sender, asset, shares, msg.sender, shares);
    }
}
