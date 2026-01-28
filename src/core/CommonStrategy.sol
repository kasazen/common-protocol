// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Auth, Authority} from "solmate/auth/Auth.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {BoringVault} from "../base/BoringVault.sol";

contract CommonStrategy is Auth {
    BoringVault public immutable vault;
    bytes32 public manageRoot;

    event ManageRootUpdated(bytes32 oldRoot, bytes32 newRoot);
    // The Voice of the protocol for the frontend feed
    event VaultPulse(string action, string rationale, uint256 timestamp);

    error Strategy__InvalidProof();

    constructor(address _owner, address _vault) Auth(_owner, Authority(address(0))) {
        vault = BoringVault(payable(_vault));
    }

    function setManageRoot(bytes32 _manageRoot) external requiresAuth {
        emit ManageRootUpdated(manageRoot, _manageRoot);
        manageRoot = _manageRoot;
    }

    /**
     * @notice The Voice of the Vault.
     * @dev Allows the strategy to log a public explanation for an action.
     */
    function pulse(string calldata action, string calldata rationale) external requiresAuth {
        emit VaultPulse(action, rationale, block.timestamp);
    }

    function manageVaultWithMerkleVerification(
        bytes32[][] calldata proofs,
        address[] calldata decodersAndSanitizers,
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) external requiresAuth {
        for (uint256 i = 0; i < targets.length; i++) {
            bytes32 leaf = keccak256(abi.encodePacked(decodersAndSanitizers[i], targets[i], data[i]));
            if (!MerkleProofLib.verify(proofs[i], manageRoot, leaf)) revert Strategy__InvalidProof();
            vault.manage(targets[i], data[i], values[i]);
        }
    }
}
