// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/AccountantWithRateProviders.sol";
import "../src/core/TellerWithMultiAssetSupport.sol";
import "../src/hooks/WorldIDHook.sol";
import "../src/base/BoringVault.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract VedaPointsSimulator is Test {
    BoringVault vault;
    AccountantWithRateProviders accountant;
    TellerWithMultiAssetSupport teller;
    WorldIDHook hook;
    MockERC20 usdc;

    address human = address(0x1337);

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        hook = new WorldIDHook();
        vault = new BoringVault(address(this), "Veda", "vWY", usdc);
        
        // Setup Core Protocol
        accountant = new AccountantWithRateProviders(
            address(this), 
            address(usdc), 
            address(hook), 
            address(0xFEED)
        );
        
        teller = new TellerWithMultiAssetSupport(
            address(this), 
            address(vault), 
            address(accountant)
        );

        // Wiring the Teller to the Accountant for point recording [cite: 15, 37, 41]
        accountant.setTeller(address(teller));
        vault.setManager(address(this));
        hook.setVerified(human, true);
    }

    function test_LoyaltyAndDAULogic() public {
        vm.startPrank(human);

        // Day 1: Initial Ping [cite: 44]
        teller.ping();
        uint256 pointsDay1 = accountant.points(human);
        assertEq(pointsDay1, 10 ether, "Should receive base points for first ping");

        // Day 15: Halfway through loyalty period
        vm.warp(block.timestamp + 15 days);
        teller.ping();
        uint256 pointsDay15 = accountant.points(human);
        assertEq(pointsDay15, 20 ether, "Should still have 1x multiplier");

        // Day 31: Loyalty Multiplier Kicks In (as defined in our optimized Accountant)
        vm.warp(block.timestamp + 16 days);
        teller.ping();
        uint256 pointsDay31 = accountant.points(human);
        
        // Accumulation logic: Day 1 (10) + Day 15 (10) + Day 31 (20 due to 2x boost)
        assertEq(pointsDay31, 40 ether, "Should receive 2x points after 30 days of loyalty");
        
        assertEq(accountant.lastInteraction(human), block.timestamp, "DAU timestamp should be current");
        vm.stopPrank();
    }
}
