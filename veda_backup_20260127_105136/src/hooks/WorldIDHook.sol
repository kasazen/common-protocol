// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract WorldIDHook {
    mapping(address => bool) public verifiedHumans;

    function beforeDeposit(address user, uint256 amount) external {
        // In production, this checks the WorldID Router
    }

    function isVerified(address user) external view returns (bool) {
        return verifiedHumans[user];
    }

    function setVerified(address user, bool status) external {
        // For testing/internal admin use
        verifiedHumans[user] = status;
    }
}
