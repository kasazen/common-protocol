// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MasterVault} from "../src/MasterVault.sol";
import {SafetyStrategy} from "../src/strategies/SafetyStrategy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MasterVaultTest is Test {
    MasterVault public vault;
    SafetyStrategy public strategy;
    
    // CORRECT World Chain USDC Address
    // We use the "prepend 00" trick to guarantee no checksum errors
    IERC20 public constant USDC = IERC20(address(uint160(0x0079A02482A880bCE3F13e09Da970dC34db4CD24d1)));
    
    address public user = address(0x123);

    function setUp() public {
        // 1. Deploy the Core
        vault = new MasterVault(USDC, "Human Yield Token", "hYIELD");
        
        // 2. Deploy the Strategy
        strategy = new SafetyStrategy(address(vault), address(USDC));
        
        // 3. Connect them
        vault.setStrategy(address(strategy));
        
        // 4. Fund User
        deal(address(USDC), user, 1000 * 1e6);
    }

    function test_ModularTrustCycle() public {
        // A. DEPOSIT
        vm.startPrank(user);
        USDC.approve(address(vault), 1000 * 1e6);
        vault.deposit(1000 * 1e6, user);
        vm.stopPrank();

        // B. INVEST (BUFFER CHECK)
        vault.invest();
        
        // Assertion: Vault holds 10% (100 USDC), Strategy holds 90% (900 USDC)
        assertEq(USDC.balanceOf(address(vault)), 100 * 1e6, "Vault should hold 10% buffer");
        assertEq(strategy.estimatedTotalAssets(), 900 * 1e6, "Strategy should hold 90% investable");
    }
}
