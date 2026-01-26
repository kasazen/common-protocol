// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../base/BoringVault.sol";

interface IAavePool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

contract AaveV3Decoder {
    // World Chain Aave Pool (Checksummed)
    address public constant POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public immutable vault;

    error AaveDecoder__InvalidTarget();
    error AaveDecoder__InvalidOnBehalfOf();
    error AaveDecoder__InvalidRecipient();
    error AaveDecoder__InvalidSelector();

    constructor(address _vault) {
        vault = _vault;
    }

    function verify(address target, bytes calldata data) external view {
        if (target != POOL) revert AaveDecoder__InvalidTarget();

        bytes4 selector = bytes4(data[:4]);

        if (selector == IAavePool.supply.selector) {
            _verifySupply(data);
        } else if (selector == IAavePool.withdraw.selector) {
            _verifyWithdraw(data);
        } else {
            revert AaveDecoder__InvalidSelector();
        }
    }

    function _verifySupply(bytes calldata data) internal view {
        // supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode)
        (,, address onBehalfOf,) = abi.decode(data[4:], (address, uint256, address, uint16));
        if (onBehalfOf != vault) revert AaveDecoder__InvalidOnBehalfOf();
    }

    function _verifyWithdraw(bytes calldata data) internal view {
        // withdraw(address asset, uint256 amount, address to)
        (,, address to) = abi.decode(data[4:], (address, uint256, address));
        if (to != vault) revert AaveDecoder__InvalidRecipient();
    }
}
