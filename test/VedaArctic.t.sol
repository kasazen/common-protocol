// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/base/BoringVault.sol";
import "../src/core/ManagerWithMerkleVerification.sol";
import "../src/core/TellerWithMultiAssetSupport.sol";
import "../src/hooks/WorldIDHook.sol";
import "../src/decoders/UniswapDecoder.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract VedaArcticTest is Test {
    BoringVault vault;
    ManagerWithMerkleVerification manager;
    TellerWithMultiAssetSupport teller;
    WorldIDHook hook;
    UniswapDecoder decoder;
    MockERC20 usdc;

    address user = address(0xABCD);
    address strategist = address(0x9999);

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        vault = new BoringVault(address(this), "Veda Yield", "vWY", usdc);
        hook = new WorldIDHook();
        manager = new ManagerWithMerkleVerification(strategist, address(vault));
        teller = new TellerWithMultiAssetSupport(address(this), address(vault), address(hook));
        decoder = new UniswapDecoder();

        // Wiring
        vault.setManager(address(manager));
        vault.transferOwnership(address(teller)); 

        // Fund User
        usdc.mint(user, 1000e6);
    }
    function test_UserDeposit_HappyPath() public {
        vm.startPrank(user);
        usdc.approve(address(teller), 1000e6);
        
        // Should succeed
        uint256 shares = teller.deposit(usdc, 1000e6, 0);
        
        assertEq(shares, 1000e6, "Shares should be 1:1");
        assertEq(vault.balanceOf(user), 1000e6, "User should have shares");
        vm.stopPrank();
    }

    function test_Withdraw_RevertsIfLocked() public {
        // 1. Deposit
        vm.startPrank(user);
        usdc.approve(address(teller), 1000e6);
        teller.deposit(usdc, 1000e6, 0);

        // 2. Try immediate withdraw (Should Fail)
        vm.expectRevert(TellerWithMultiAssetSupport.Teller__SharesLocked.selector);
        teller.withdraw(1000e6, 0);
        vm.stopPrank();
    }

    function test_Withdraw_SucceedsAfterTime() public {
        vm.startPrank(user);
        usdc.approve(address(teller), 1000e6);
        teller.deposit(usdc, 1000e6, 0);

        // 3. Warps time forward 2 days
        vm.warp(block.timestamp + 2 days);

        teller.withdraw(1000e6, 0);
        assertEq(usdc.balanceOf(user), 1000e6, "User got funds back");
        vm.stopPrank();
    }
    function test_Manager_RevertsMaliciousTx() public {
        // 1. Setup Strategy
        address target = address(0x1234);
        bytes memory goodData = hex"112233";
        bytes32 leaf = keccak256(abi.encodePacked(address(decoder), target, goodData));
        
        // 2. Auth Good Strategy
        vm.prank(strategist);
        manager.setManageRoot(leaf);

        // 3. Attempt Malicious Data (Same target, different payload)
        bytes memory badData = hex"DEADBEEF"; 
        
        bytes32[][] memory proofs = new bytes32[][](1);
        address[] memory decoders = new address[](1); decoders[0] = address(decoder);
        address[] memory targets = new address[](1); targets[0] = target;
        bytes[] memory datas = new bytes[](1); datas[0] = badData; 
        uint256[] memory values = new uint256[](1);

        // 4. Expect Revert
        vm.prank(strategist);
        vm.expectRevert(ManagerWithMerkleVerification.Manager__InvalidProof.selector);
        manager.manageVaultWithMerkleVerification(proofs, decoders, targets, datas, values);
    }
}
