// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UniswapDecoder {
    function exactInput(
        bytes memory path,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMinimum
    ) external pure returns (bytes memory) {
        return abi.encode(path, recipient, amountIn, amountOutMinimum);
    }
}
