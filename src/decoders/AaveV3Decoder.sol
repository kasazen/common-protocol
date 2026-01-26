// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IAavePool {
    function setUserEMode(uint8 categoryId) external;
}

contract AaveV3Decoder {
    address public constant POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    
    function verify(address target, bytes calldata data) external pure {
        require(target == POOL, "InvalidTarget");
        if (bytes4(data[:4]) == IAavePool.setUserEMode.selector) {
            uint8 categoryId = abi.decode(data[4:], (uint8));
            require(categoryId == 1, "MustUseStableEMode");
        }
    }
}
