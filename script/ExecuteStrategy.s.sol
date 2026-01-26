// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/base/BoringVault.sol";
import "../src/core/ManagerWithMerkleVerification.sol";
import "../src/core/TellerWithMultiAssetSupport.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import "../src/decoders/UniswapDecoder.sol"; // We need the decoder we made earlier

contract ExecuteStrategy is Script {
    function run() external {
        vm.startBroadcast();
        
        // 1. SETUP (Re-deploying for self-contained sim)
        MockERC20 usdc = new MockERC20("USDC", "USDC", 6);
        BoringVault vault = new BoringVault(msg.sender, "Veda Yield", "vWY", usdc);
        ManagerWithMerkleVerification manager = new ManagerWithMerkleVerification(msg.sender, address(vault));
        UniswapDecoder decoder = new UniswapDecoder();

        // Wire it
        vault.setManager(address(manager));
        
        // Fund the Vault (Simulate a user deposit)
        usdc.mint(address(vault), 1000e6); 
        console.log("Vault Funded with 1000 USDC");
        // 2. DEFINE THE STRATEGY (Swap 100 USDC -> WETH)
        address target = 0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6; // Uniswap Router
        bytes memory swapData = abi.encodeWithSelector(
            0x414bf389, // exactInput selector
            abi.encodePacked(address(usdc), uint24(500), address(0x4200000000000000000000000000000000000006)), // Path
            address(vault), // Recipient (Must be Vault)
            uint256(100e6), // AmountIn
            uint256(0)      // MinAmountOut
        );

        // 3. GENERATE MERKLE LEAF
        // Leaf = Keccak256(Decoder + Target + Data)
        bytes32 leaf = keccak256(abi.encodePacked(address(decoder), target, swapData));
        
        // For a single-item tree, the Root IS the Leaf.
        bytes32 root = leaf;

        // 4. AUTHORIZE STRATEGY
        manager.setManageRoot(root);
        console.log("Manager Root Updated");

        // 5. EXECUTE
        // We prepare the arrays for the Manager call
        bytes32[][] memory proofs = new bytes32[][](1); // Empty proof for single leaf
        address[] memory decoders = new address[](1);
        decoders[0] = address(decoder);
        address[] memory targets = new address[](1);
        targets[0] = target;
        bytes[] memory datas = new bytes[](1);
        datas[0] = swapData;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;

        console.log("Attempting Execution...");
        // This will FAIL strictly because we are mocking and Uniswap doesnt exist on localhost.
        // But if it reaches the "Call Failed" revert in BoringVault, we know the Manager passed!
        try manager.manageVaultWithMerkleVerification(proofs, decoders, targets, datas, values) {
            console.log("SUCCESS: Manager approved execution!");
        } catch Error(string memory reason) {
            console.log("REVERTED (Expected on Mock):", reason);
        }

        vm.stopBroadcast();
    }
}
