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
        // Fixed: Added 5th argument (address(0) for Oracle)
        accountant = new AccountantWithRateProviders(
            address(this), 
            address(usdc), 
            address(hook), 
            feeSplitter, 
            address(0)
        );
    }

    function test_PerformanceFeeLogic() public {
        uint256 grossNewRate = 1.0008e18; 
        accountant.updateRate(grossNewRate);
        uint256 finalRate = accountant.lastRate();
        
        // Profit 8bps -> 2bps fee (25%) -> 6bps net
        assertEq(finalRate, 1.0006e18, "Users should see 75% of profit");
    }
}
