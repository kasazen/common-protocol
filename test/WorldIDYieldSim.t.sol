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

    address human = address(0x111);

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        hook = new WorldIDHook();
        vault = new BoringVault(address(this), "Veda", "vWY", usdc);
        accountant = new AccountantWithRateProviders(address(this), address(usdc), address(hook), address(0xFEED));
        teller = new TellerWithMultiAssetSupport(address(this), address(vault), address(accountant));

        // CRITICAL: Authorize the teller
        accountant.setTeller(address(teller));
        
        vault.setManager(address(this));
        hook.setVerified(human, true);
    }

    function test_FuelAccrualOnPing() public {
        vm.startPrank(human);
        uint256 pointsBefore = accountant.points(human);
        teller.ping();
        uint256 pointsAfter = accountant.points(human);
        
        assertGt(pointsAfter, pointsBefore, "Fuel tank should fill up");
        vm.stopPrank();
    }
}
