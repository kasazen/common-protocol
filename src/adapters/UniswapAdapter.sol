// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// INTERFACE: SwapRouter02 (Correct World Chain Standard)
// Note: NO 'deadline' field. This was the cause of previous crashes.
interface ISwapRouter02 {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
}

contract UniswapAdapter is Ownable {
    using SafeERC20 for IERC20;

    address public immutable asset;
    address public immutable router; 
    
    // World Chain Constants
    address public constant WC_USDC = 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1;
    address public constant WC_WETH = 0x4200000000000000000000000000000000000006;
    address public constant WC_ROUTER = 0x091AD9e2e6e5eD44c1c66dB50e49A601F9f36cF6;

    constructor() Ownable(msg.sender) {
        asset = WC_USDC;
        router = WC_ROUTER;
    }

    function deposit(uint256 amount) external {
        // 1. Safety Check: Ensure we actually received the funds
        uint256 myBalance = IERC20(asset).balanceOf(address(this));
        require(myBalance >= amount, "Adapter: Funds not received");

        // 2. Approve Router
        IERC20(asset).approve(router, amount);

        // 3. Path: USDC -> Fee 500 (0.05%) -> WETH
        bytes memory path = abi.encodePacked(WC_USDC, uint24(500), WC_WETH);

        // 4. Swap (Router02 Format)
        ISwapRouter02.ExactInputParams memory params = ISwapRouter02.ExactInputParams({
            path: path,
            recipient: address(this),
            amountIn: amount,
            amountOutMinimum: 0 
        });

        ISwapRouter02(router).exactInput(params);
    }
}
