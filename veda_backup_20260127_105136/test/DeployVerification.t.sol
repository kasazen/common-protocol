// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/AccountantWithRateProviders.sol";
import "../src/core/TellerWithMultiAssetSupport.sol";
import "../src/core/VedaArcticLens.sol";
import "../src/core/RevenueSplitter.sol";
import "../src/hooks/WorldIDHook.sol";
import "../src/base/BoringVault.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract DeployVerification is Test {
    BoringVault vault;
    AccountantWithRateProviders accountant;
    TellerWithMultiAssetSupport teller;
    WorldIDHook hook;
    RevenueSplitter splitter;
    VedaArcticLens lens;
    MockERC20 usdc;

    address mainOwner = address(0xAAAA);
    address testPartner = address(0xBBBB);
    address human = address(0xCCCC);

    function setUp() public {
        vm.startPrank(mainOwner);
        usdc = new MockERC20("USDC", "USDC", 6);
        hook = new WorldIDHook(); 
        splitter = new RevenueSplitter(mainOwner, testPartner);
        lens = new VedaArcticLens();

        accountant = new AccountantWithRateProviders(mainOwner, address(usdc), address(hook), address(splitter));
        vault = new BoringVault(payable(mainOwner), "Veda Arctic", "vUSDC", usdc);
        teller = new TellerWithMultiAssetSupport(mainOwner, address(vault), address(accountant));

        accountant.setTeller(address(teller));
        vault.setManager(mainOwner);
        hook.setVerified(human, true);
        vm.stopPrank();
    }

    function test_DeploymentWiring() public view {
        assertEq(accountant.teller(), address(teller));
        assertEq(address(teller.ACCOUNTANT()), address(accountant));
        assertEq(accountant.feeRecipient(), address(splitter));
    }

    function test_LensDataIntegrity() public {
        VedaArcticLens.Dashboard memory d = lens.getDashboard(human, address(vault), address(accountant), address(teller));
        assertEq(d.isVerified, true);
    }
}
