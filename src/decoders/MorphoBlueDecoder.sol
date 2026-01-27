// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMorphoBlue {
    struct MarketParams {
        address loanToken;
        address collateralToken;
        address oracle;
        address irm; 
        uint256 lltv; 
    }
    function supply(MarketParams memory, uint256, uint256, address, bytes memory) external returns (uint256, uint256);
    function withdraw(MarketParams memory, uint256, uint256, address, address) external returns (uint256, uint256);
    function borrow(MarketParams memory, uint256, uint256, address, address) external returns (uint256, uint256);
    function repay(MarketParams memory, uint256, uint256, address, bytes memory) external returns (uint256, uint256);
}

contract MorphoBlueDecoder {
    address public immutable MORPHO_BLUE;
    address public immutable USDC;
    error MorphoDecoder__InvalidTarget();
    error MorphoDecoder__InvalidLoanToken();
    error MorphoDecoder__InvalidFunction();

    constructor(address _morphoBlue, address _usdc) {
        MORPHO_BLUE = _morphoBlue;
        USDC = _usdc;
    }

    function verify(address target, bytes calldata data) external view {
        if (target != MORPHO_BLUE) revert MorphoDecoder__InvalidTarget();
        bytes4 selector = bytes4(data[:4]);
        IMorphoBlue.MarketParams memory params;

        if (
            selector == IMorphoBlue.supply.selector ||
            selector == IMorphoBlue.withdraw.selector ||
            selector == IMorphoBlue.borrow.selector ||
            selector == IMorphoBlue.repay.selector
        ) {
            (params) = abi.decode(data[4:164], (IMorphoBlue.MarketParams));
            // Safety Check: Only allow USDC loans
            if (params.loanToken != USDC) revert MorphoDecoder__InvalidLoanToken();
        } else {
            revert MorphoDecoder__InvalidFunction();
        }
    }
}
