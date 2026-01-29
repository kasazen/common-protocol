// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CommonVault is ERC4626, Ownable {
    // This constructor matches our deploy script (1 argument only)
    constructor(IERC20 asset) 
        ERC4626(asset) 
        ERC20("Common Vault USDC", "vUSDC") 
        Ownable(msg.sender) 
    {}
}
