// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {Ownable} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol";
import {IQuickswapRouter} from "../interfaces/IQuickswapRouter.sol";
import {IUniswapRouter} from "../interfaces/IUniswapRouter.sol";
import {IPearlRouter} from "../interfaces/IPearlRouter.sol";

contract FlashLoan is FlashLoanSimpleReceiverBase, Ownable {
    address immutable uniswapRouter;
    address immutable quickswapRouter;
    address immutable pearlRouter;

    constructor(
        address _uniswapRouter,
        address _quickswapRouter,
        address _pearlRouter,
        address _aavePoolAddressProvider
    )
        FlashLoanSimpleReceiverBase(
            IPoolAddressesProvider(_aavePoolAddressProvider)
        )
    {
        uniswapRouter = _uniswapRouter;
        quickswapRouter = _quickswapRouter;
        pearlRouter = _pearlRouter;
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);
        return true;
    }

    function withdraw(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function quickswapUniswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint24 fee
    ) external returns (uint256 amountOut) {
        POOL.flashLoanSimple(address(this), tokenIn, amountIn, "", 0);
        amountOut = quickswap({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn
        });
        amountOut = uniswap({
            tokenIn: tokenOut,
            tokenOut: tokenIn,
            fee: fee,
            amountIn: amountOut
        });
        require(amountOut >= amountOutMin, "amountOut >= amountOutMin");
    }

    function uniswapQuickswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint24 fee
    ) external returns (uint256 amountOut) {
        POOL.flashLoanSimple(address(this), tokenIn, amountIn, "", 0);
        amountOut = uniswap({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            amountIn: amountIn
        });
        amountOut = quickswap({
            tokenIn: tokenOut,
            tokenOut: tokenIn,
            amountIn: amountOut
        });
        require(amountOut >= amountOutMin, "amountOut >= amountOutMin");
    }

    function pearlUniswap(
        address tokenA,
        bool stableAB,
        address tokenB,
        bool stableBC,
        address tokenC,
        uint24 feeCA,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (uint256 amountOut) {
        POOL.flashLoanSimple(address(this), tokenA, amountIn, "", 0);
        amountOut = pearl({
            tokenIn: tokenA,
            tokenOut: tokenB,
            stable: stableAB,
            amountIn: amountIn
        });
        amountOut = pearl({
            tokenIn: tokenB,
            tokenOut: tokenC,
            stable: stableBC,
            amountIn: amountOut
        });
        amountOut = uniswap({
            tokenIn: tokenC,
            tokenOut: tokenA,
            fee: feeCA,
            amountIn: amountOut
        });
        require(amountOut >= amountOutMin, "amountOut >= amountOutMin");
    }

    function quickswap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint amountOut) {
        IERC20(tokenIn).approve(quickswapRouter, amountIn);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint[] memory amounts = IQuickswapRouter(quickswapRouter)
            .swapExactTokensForTokens({
                amountIn: amountIn,
                amountOutMin: 0,
                path: path,
                to: address(this),
                deadline: block.timestamp
            });
        amountOut = amounts[amounts.length - 1];
    }

    function uniswap(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        IERC20(tokenIn).approve(uniswapRouter, amountIn);
        amountOut = IUniswapRouter(uniswapRouter).exactInputSingle(
            IUniswapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function pearl(
        address tokenIn,
        address tokenOut,
        bool stable,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        IERC20(tokenIn).approve(pearlRouter, amountIn);
        uint256[] memory amounts = IPearlRouter(pearlRouter)
            .swapExactTokensForTokensSimple({
                amountIn: amountIn,
                amountOutMin: 0,
                tokenFrom: tokenIn,
                tokenTo: tokenOut,
                stable: stable,
                to: address(this),
                deadline: block.timestamp
            });
        amountOut = amounts[amounts.length - 1];
    }
}
