// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/AccountantWithRateProviders.sol";
import "../src/hooks/WorldIDHook.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract FeeCollectionSim is Test {
    AccountantWithRateProviders accountant;
    WorldIDHook hook;
    MockERC20 usdc;
    address feeSplitter = address(0xFEED);

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        hook = new WorldIDHook();
        accountant = new AccountantWithRateProviders(
            address(this), 
            address(usdc), 
            address(hook), 
            feeSplitter
        );
    }

    function test_PerformanceFeeLogic() public {
        uint256 grossNewRate = 1.0008e18; 
        accountant.updateRate(grossNewRate);
        assertEq(accountant.lastRate(), 1.0006e18);
    }
}
