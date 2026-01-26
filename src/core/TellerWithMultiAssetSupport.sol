// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import "../base/BoringVault.sol";
import "../hooks/WorldIDHook.sol";

contract TellerWithMultiAssetSupport is Auth {
    using SafeTransferLib for ERC20;

    BoringVault public immutable VAULT;
    WorldIDHook public immutable HOOK;
    
    mapping(address => uint256) public depositTimestamp;
    uint256 public constant SHARE_LOCK_PERIOD = 1 days;

    error Teller__SharesLocked();
    error Teller__NotVerifiedHuman();

    constructor(address _owner, address _vault, address _hook) 
        Auth(_owner, Authority(address(0))) 
    {
        VAULT = BoringVault(_vault);
        HOOK = WorldIDHook(_hook);
    }

    function deposit(ERC20 asset, uint256 amount, uint256) external returns (uint256 shares) {
        // WORLD ID GATE: Strictly Human Only
        if (!HOOK.isVerified(msg.sender)) revert Teller__NotVerifiedHuman();

        asset.safeTransferFrom(msg.sender, address(VAULT), amount);
        
        shares = amount; // 1:1 Initial
        VAULT.enter(msg.sender, asset, amount, msg.sender, shares);
        
        depositTimestamp[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 shares, uint256) external {
        if (block.timestamp < depositTimestamp[msg.sender] + SHARE_LOCK_PERIOD) 
            revert Teller__SharesLocked();
        
        VAULT.exit(msg.sender, VAULT.asset(), shares, msg.sender, shares);
    }
}
