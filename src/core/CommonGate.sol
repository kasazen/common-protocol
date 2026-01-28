// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import "../base/BoringVault.sol";
import "./CommonRates.sol";

contract CommonGate is Auth {
    using SafeTransferLib for ERC20;
    BoringVault public immutable VAULT;
    CommonRates public immutable ACCOUNTANT;
    
    mapping(address => uint256) public depositTimestamp;
    uint256 public constant SHARE_LOCK_PERIOD = 1 days;

    struct HumanStatus {
        bool isVerified;
        bool gasSubsidyActive;
        uint256 currentYieldBoost;
    }

    constructor(address _owner, address _vault, address _rates) 
        Auth(_owner, Authority(address(0))) 
    {
        VAULT = BoringVault(payable(_vault));
        ACCOUNTANT = CommonRates(_rates);
    }

    function getHumanStatus(address user) public view returns (HumanStatus memory) {
        bool verified = ACCOUNTANT.HOOK().isVerified(user);
        return HumanStatus(verified, verified, verified ? 2000 : 0);
    }

    function deposit(ERC20 asset, uint256 amount) external returns (uint256 shares) {
        if (!ACCOUNTANT.HOOK().isVerified(msg.sender)) revert("NotHuman");
        asset.safeTransferFrom(msg.sender, address(VAULT), amount);
        shares = amount; 
        VAULT.enter(msg.sender, asset, amount, msg.sender, shares);
        depositTimestamp[msg.sender] = block.timestamp;
        ACCOUNTANT.recordInteraction(msg.sender);
    }

    function ping() external {
        if (!ACCOUNTANT.HOOK().isVerified(msg.sender)) revert("NotHuman");
        ACCOUNTANT.recordInteraction(msg.sender);
    }

    function withdraw(uint256 shares) external {
        require(block.timestamp >= depositTimestamp[msg.sender] + SHARE_LOCK_PERIOD, "LOCKED");
        VAULT.exit(msg.sender, VAULT.asset(), shares, msg.sender, shares);
    }
}
