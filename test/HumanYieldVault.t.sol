// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {HumanYieldVault} from "../src/HumanYieldVault.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract HumanYieldVaultTest is Test {
    HumanYieldVault public vault;
    MockUSDC public usdc;
    address public whale = address(0x123); // The User
    address public owner = address(this);  // The Manager (You)

    function setUp() public {
        usdc = new MockUSDC();
        vault = new HumanYieldVault(usdc);
        
        // Fund the User
        usdc.mint(whale, 10000e18);
        vm.prank(whale);
        usdc.approve(address(vault), 10000e18);
    }

    function test_FullTrustCycle() public {
        // 1. User Deposits $1,000
        vm.prank(whale);
        vault.deposit(1000e18, whale);

        // 2. Manager Invests $900
        vault.invest(900e18);
        
        // Verify money moved to Manager
        assertEq(usdc.balanceOf(owner), 900e18);
        assertEq(vault.totalInvested(), 900e18);

        // 3. Manager makes $100 Profit (External World)
        // We simulate this by minting extra money to the manager
        usdc.mint(owner, 100e18); 

        // 4. Manager Repays $1,000 ($900 Principal + $100 Profit)
        usdc.approve(address(vault), 1000e18); // Manager approves vault to pull funds
        vault.repay(1000e18);

        // Verify:
        // - Vault should now hold $1,100 ($100 liquid + $1,000 returned)
        // - TotalInvested should be 0 (Debt cleared)
        assertEq(usdc.balanceOf(address(vault)), 1100e18);
        assertEq(vault.totalInvested(), 0);
    }
}