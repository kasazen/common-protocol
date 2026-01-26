// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol";
import "../src/core/AccountantWithRateProviders.sol";
import "../src/core/TellerWithMultiAssetSupport.sol";
import "../src/hooks/WorldIDHook.sol";
import "../src/base/BoringVault.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract WorldIDYieldSim is Test {
    BoringVault vault;
    AccountantWithRateProviders accountant;
    TellerWithMultiAssetSupport teller;
    WorldIDHook hook;
    MockERC20 usdc;

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        hook = new WorldIDHook();
        vault = new BoringVault(address(this), "Veda", "vWY", usdc);
        // Using address(0) for oracle in test setup
        accountant = new AccountantWithRateProviders(address(this), address(usdc), address(hook), address(0xFEED), address(0));
        teller = new TellerWithMultiAssetSupport(address(this), address(vault), address(hook));
    }

    function test_HumanOnlyGate() public {
        address bot = address(0xB07);
        vm.prank(bot);
        vm.expectRevert(TellerWithMultiAssetSupport.Teller__NotVerifiedHuman.selector);
        teller.deposit(usdc, 100e6, 0);
    }
}
