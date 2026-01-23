// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MasterVault} from "../src/MasterVault.sol";
import {YieldDirector} from "../src/director/YieldDirector.sol";
import {MockAdapter} from "../src/mocks/MockAdapter.sol"; // Use Mock for reliability
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MasterVaultTest is Test {
    MasterVault public vault;
    YieldDirector public director;
    MockAdapter public mockStrategy;
    
    // World Chain USDC (Checksummed)
    IERC20 public constant USDC = IERC20(address(uint160(0x0079A02482A880bCE3F13e09Da970dC34db4CD24d1)));
    address public user = address(0x123);

    function setUp() public {
        director = new YieldDirector();
        vault = new MasterVault(USDC, address(director));
        
        // Deploy Mock Strategy with 5% APY
        mockStrategy = new MockAdapter(address(vault), address(USDC));
        
        // Add it to the Brain
        director.addAdapter(address(mockStrategy));
        
        deal(address(USDC), user, 1000 * 1e6);
    }

    function test_AutonomousYieldRouting() public {
        // 1. User Deposits
        vm.startPrank(user);
        USDC.approve(address(vault), 1000 * 1e6);
        vault.deposit(1000 * 1e6, user);
        vm.stopPrank();

        // 2. Trigger the "Brain" to find the best yield
        vault.rebalance();
        
        // 3. Verify the Vault correctly moved funds to the Mock Strategy
        assertEq(address(vault.currentAdapter()), address(mockStrategy), "Vault failed to route to the Mock Strategy");
        
        // 4. Verify Strategy is holding the funds (900 USDC = 90% of 1000)
        assertEq(mockStrategy.totalAssets(), 900 * 1e6, "Funds did not reach the strategy");
        
        console.log("Success! Routed to Strategy with APR:", mockStrategy.getApr());
    }
}
