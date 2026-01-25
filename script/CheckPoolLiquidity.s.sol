// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract CheckPoolLiquidity is Script {
    function run() external view {
        console.log("====== UNISWAP POOL DIAGNOSTIC ======");

        address FACTORY = 0x7a5028BDa40e7B173C278C5342087826455ea25a;
        address USDC    = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
        address WETH    = 0x4200000000000000000000000000000000000006;

        // Check the 3 main fee tiers
        checkTier(FACTORY, USDC, WETH, 500);   // 0.05% (Likely the winner)
        checkTier(FACTORY, USDC, WETH, 3000);  // 0.30% (What we used)
        checkTier(FACTORY, USDC, WETH, 10000); // 1.00% (Rare)

        console.log("====== END DIAGNOSTIC ======");
    }

    function checkTier(address factory, address t0, address t1, uint24 fee) internal view {
        address pool = IUniswapV3Factory(factory).getPool(t0, t1, fee);
        if (pool != address(0)) {
            // Check how much WETH is actually inside the pool
            uint256 wethLiquidity = IERC20(t1).balanceOf(pool);
            console.log("Tier", fee, "Pool Address:", pool);
            console.log("   -> WETH Liquidity:", wethLiquidity);
            if (wethLiquidity == 0) console.log("   -> [WARNING] POOL IS EMPTY");
        } else {
            console.log("Tier", fee, "Pool: DOES NOT EXIST");
        }
    }
}
