// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/base/BoringVault.sol";
import "../src/core/ManagerWithMerkleVerification.sol";
import "../src/decoders/UniswapDecoder.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";

contract BlockMaliciousTx is Script {
    function run() external {
        vm.startBroadcast();
        
        // 1. SETUP
        MockERC20 usdc = new MockERC20("USDC", "USDC", 6);
        BoringVault vault = new BoringVault(msg.sender, "Veda Yield", "vWY", usdc);
        ManagerWithMerkleVerification manager = new ManagerWithMerkleVerification(msg.sender, address(vault));
        UniswapDecoder decoder = new UniswapDecoder();
        
        vault.setManager(address(manager));
        usdc.mint(address(vault), 1000e6);
        // 2. AUTHORIZE "GOOD" TRANSACTION (Swap for WETH)
        address goodTarget = 0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6; 
        bytes memory goodData = abi.encode(address(usdc), uint256(100)); 
        
        // The Root is set based on this GOOD data
        bytes32 leaf = keccak256(abi.encodePacked(address(decoder), goodTarget, goodData));
        manager.setManageRoot(leaf);
        console.log("Manager Authorized: GOOD Tx Only");
        // 3. ATTEMPT "BAD" TRANSACTION (Changing the data payload)
        bytes memory badData = abi.encode(address(usdc), uint256(999999)); 

        // Prepare the arrays for the Malicious Call
        bytes32[][] memory proofs = new bytes32[][](1); 
        address[] memory decoders = new address[](1);
        decoders[0] = address(decoder);
        address[] memory targets = new address[](1);
        targets[0] = goodTarget;
        
        bytes[] memory datas = new bytes[](1);
        datas[0] = badData; // <--- THE MALICIOUS PAYLOAD
        
        uint256[] memory values = new uint256[](1);

        console.log("Attempting Malicious Execution...");

        // 4. VERIFY REJECTION
        try manager.manageVaultWithMerkleVerification(proofs, decoders, targets, datas, values) {
            console.log("CRITICAL FAILURE: Malicious Tx was ALLOWED!");
        } catch {
            console.log("SUCCESS: Tx Blocked (Invalid Proof).");
        }

        vm.stopBroadcast();
    }
}
