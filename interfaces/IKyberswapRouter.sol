// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKyberswapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 minAmountOut;
        uint160 limitSqrtP;
    }

    function swapExactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}
