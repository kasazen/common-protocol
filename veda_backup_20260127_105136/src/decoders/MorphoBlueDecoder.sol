// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMorphoBlue {
    // Morpho Blue Market Params Struct
    struct MarketParams {
        address loanToken;
        address collateralToken;
        address oracle;
        address irm; 
        uint256 lltv; 
    }

    function supply(
        MarketParams memory marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        bytes memory data
    ) external returns (uint256, uint256);

    function withdraw(
        MarketParams memory marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        address receiver
    ) external returns (uint256, uint256);

    function borrow(
        MarketParams memory marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        address receiver
    ) external returns (uint256, uint256);

    function repay(
        MarketParams memory marketParams,
        uint256 assets,
        uint256 shares,
        address onBehalf,
        bytes memory data
    ) external returns (uint256, uint256);
}

contract MorphoBlueDecoder {
    // -----------------------------------------------------------------------
    // Immutable Storage (Verified World Chain Addresses)
    // -----------------------------------------------------------------------
    
    // Canonical Morpho Blue (Same address on all chains)
    // EIP-55 Checksum: 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb
    address public immutable MORPHO_BLUE;
    
    // Native World Chain USDC
    // EIP-55 Checksum: 0x79A02482A880bCE3F13e09Da970dC34db4CD24d1
    address public immutable USDC;
    
    // -----------------------------------------------------------------------
    // Errors
    // -----------------------------------------------------------------------
    
    error MorphoDecoder__InvalidTarget();
    error MorphoDecoder__InvalidLoanToken();
    error MorphoDecoder__InvalidFunction();

    // -----------------------------------------------------------------------
    // Initialization
    // -----------------------------------------------------------------------

    constructor(address _morphoBlue, address _usdc) {
        MORPHO_BLUE = _morphoBlue;
        USDC = _usdc;
    }

    // -----------------------------------------------------------------------
    // Decoder Logic
    // -----------------------------------------------------------------------

    /**
     * @notice Decodes and verifies a transaction for the Manager.
     * @dev    This is the "Safety Valve" that prevents the Manager from
     * executing dangerous or unauthorized interactions.
     */
    function verify(address target, bytes calldata data) external view {
        // 1. Target Security Check
        if (target != MORPHO_BLUE) revert MorphoDecoder__InvalidTarget();

        // 2. Function Selector Extraction
        bytes4 selector = bytes4(data[:4]);

        // 3. Decode MarketParams to ensure Safety
        // All major Morpho interactions start with MarketParams struct
        IMorphoBlue.MarketParams memory params;

        if (
            selector == IMorphoBlue.supply.selector ||
            selector == IMorphoBlue.withdraw.selector ||
            selector == IMorphoBlue.borrow.selector ||
            selector == IMorphoBlue.repay.selector
        ) {
            // Decoding the struct from calldata (standard ABI encoding)
            (params) = abi.decode(data[4:164], (IMorphoBlue.MarketParams));
            
            // 4. Asset Security Check (The "Smart" Logic)
            // CRITICAL: We only allow interactions where the Loan Token is USDC.
            // This allows us to "Loop" USDC/USDC or USDC/Dai, but strictly prevents
            // borrowing volatile assets like WETH or WLD.
            if (params.loanToken != USDC) revert MorphoDecoder__InvalidLoanToken();
        } else {
            // Block any other function calls (like flashLoan)
            revert MorphoDecoder__InvalidFunction();
        }
    }
}
