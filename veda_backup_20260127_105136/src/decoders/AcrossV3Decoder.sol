// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
interface IAcrossSpokePool {
    function deposit(address recipient, address originToken, uint256 amount, uint256 destinationChainId, uint64 relayerFeePct, uint32 quoteTimestamp, bytes memory message, uint256 maxSamples) external;
}
contract AcrossV3Decoder {
    address public constant SPOKE_POOL = 0x09aea4b2242abC8bb4BB78D537A67a245A7bEC64;
    address public immutable vault;
    uint32 public constant QUOTE_BUFFER = 1 hours;
    constructor(address _vault) { vault = _vault; }
    function verify(address target, bytes calldata data) external view {
        require(target == SPOKE_POOL, "Invalid Target");
        if (bytes4(data[:4]) == IAcrossSpokePool.deposit.selector) {
            address recipient = abi.decode(data[4:36], (address));
            require(recipient == vault, "Invalid Recipient");
            uint32 quoteTimestamp = abi.decode(data[164:196], (uint32));
            require(block.timestamp <= quoteTimestamp + QUOTE_BUFFER, "Quote Expired");
        }
    }
}
