// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {Ownable} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol";
import {IQuickswapRouter} from "../interfaces/IQuickswapRouter.sol";
import {IUniswapRouter} from "../interfaces/IUniswapRouter.sol";
import {IPearlRouter} from "../interfaces/IPearlRouter.sol";
import {IWUSDR} from "../interfaces/IWUSDR.sol";

enum Action {
    UNISWAP,
    PEARL,
    QUICKSWAP,
    WUSDRUSDR,
    USDRWUSDR
}

contract FlashLoan3 is FlashLoanSimpleReceiverBase, Ownable {
    address private constant usdr = 0xb5DFABd7fF7F83BAB83995E72A52B97ABb7bcf63;
    address private constant wusdr = 0xAF0D9D65fC54de245cdA37af3d18cbEc860A4D4b;
    address private constant uniswapRouter =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address private constant quickswapRouter =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    address private constant pearlRouter =
        0xcC25C0FD84737F44a7d38649b69491BBf0c7f083;

    constructor(
        address _aavePoolAddressProvider
    )
        FlashLoanSimpleReceiverBase(
            IPoolAddressesProvider(_aavePoolAddressProvider)
        )
    {}

    function withdraw(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function arb(
        address tokenIn,
        uint256 amountIn,
        bytes memory data
    ) external {
        POOL.flashLoanSimple(address(this), tokenIn, amountIn, data, 0);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes memory params
    ) external override returns (bool) {
        uint256 amountOut = amount;
        while (params.length > 0) {
            Action action;
            (, action) = abi.decode(params, (bytes, Action));
            if (action == Action.UNISWAP) {
                amountOut = uniswap(amountOut, params);
            } else if (action == Action.PEARL) {
                amountOut = pearl(amountOut, params);
            } else if (action == Action.QUICKSWAP) {
                amountOut = quickswap(amountOut, params);
            } else if (action == Action.USDRWUSDR) {
                amountOut = usdrwusdr(amountOut);
            } else if (action == Action.WUSDRUSDR) {
                amountOut = wusdrusdr(amountOut);
            }
            (params) = abi.decode(params, (bytes));
        }
        require(amountOut >= amount + premium, "amountOut < amount + premium");
        IERC20(asset).approve(address(POOL), amount + premium);
        return true;
    }

    function uniswap(
        uint256 amountIn,
        bytes memory data
    ) internal returns (uint256 amountOut) {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        (, , tokenIn, tokenOut, fee) = abi.decode(
            data,
            (bytes, Action, address, address, uint24)
        );
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

    function quickswap(
        uint256 amountIn,
        bytes memory data
    ) internal returns (uint amountOut) {
        address tokenIn;
        address tokenOut;
        (, , tokenIn, tokenOut) = abi.decode(
            data,
            (bytes, Action, address, address)
        );
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

    function pearl(
        uint256 amountIn,
        bytes memory data
    ) internal returns (uint256 amountOut) {
        address tokenIn;
        address tokenOut;
        bool stable;
        (, , tokenIn, tokenOut, stable) = abi.decode(
            data,
            (bytes, Action, address, address, bool)
        );
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

    function usdrwusdr(uint256 amountIn) internal returns (uint256 amountOut) {
        IERC20(usdr).approve(wusdr, amountIn);
        amountOut = IWUSDR(wusdr).deposit(amountIn, address(this));
    }

    function wusdrusdr(uint256 amountIn) internal returns (uint256 amountOut) {
        IERC20(wusdr).approve(usdr, amountIn);
        amountOut = IWUSDR(wusdr).redeem(
            amountIn,
            address(this),
            address(this)
        );
    }
}
