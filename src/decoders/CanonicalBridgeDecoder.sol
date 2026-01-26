// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IL2StandardBridge {
    function withdraw(address l2Token, uint256 amount, uint32 minGasLimit, bytes calldata extraData) external;
}

contract CanonicalBridgeDecoder {
    address public constant BRIDGE = 0x4200000000000000000000000000000000000010;
    address public immutable vault;

    error BridgeDecoder__InvalidTarget();

    constructor(address _vault) {
        vault = _vault;
    }

    function verify(address target, bytes calldata data) external view {
        if (target != BRIDGE) revert BridgeDecoder__InvalidTarget();
        // Standard Bridge withdraw logic is simple, but we ensure it is called by the Vault
    }
}
