// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/base/BoringVault.sol";
import "../src/core/ManagerWithMerkleVerification.sol";
import "../src/core/TellerWithMultiAssetSupport.sol";
import "../src/core/AccountantWithRateProviders.sol";
import "../src/hooks/WorldIDHook.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract VedaArcticTest is Test {
    BoringVault vault;
    AccountantWithRateProviders accountant;
    TellerWithMultiAssetSupport teller;
    WorldIDHook hook;
    MockERC20 usdc;

    address user = address(0xABCD);

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        hook = new WorldIDHook();
        accountant = new AccountantWithRateProviders(address(this), address(usdc), address(hook), address(0x1));
        vault = new BoringVault(address(this), "Veda Yield", "vWY", usdc);
        teller = new TellerWithMultiAssetSupport(address(this), address(vault), address(accountant));

        vault.setManager(address(this));
        hook.setVerified(user, true);
        usdc.mint(user, 1000e6);
    }

    function test_UserDeposit_HappyPath() public {
        vm.startPrank(user);
        usdc.approve(address(teller), 1000e6);
        uint256 shares = teller.deposit(usdc, 1000e6);
        assertEq(shares, 1000e6);
        vm.stopPrank();
    }
}
