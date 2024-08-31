// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniswapV2} from "../interfaces/IUniswapV2.sol";
import {IUniswapV3} from "../interfaces/IUniswapV3.sol";
import {IPearl} from "../interfaces/IPearl.sol";
import {IKyberswap} from "../interfaces/IKyberswap.sol";

error InvalidAction(Action action);
error AmountOutMinNotReached(uint256 amountOut, uint256 amountOutMin);

enum Action {
    UNISWAPV2,
    UNISWAPV3,
    PEARL,
    QUICKSWAPV2,
    QUICKSWAPV3,
    RETRO,
    KYBERSWAP,
    SUSHISWAPV2
}

contract Arbitrage is Ownable {
    constructor() Ownable(msg.sender) {}

    function withdraw(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function arb(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes memory data
    ) external onlyOwner returns (uint256 amountOut) {
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        amountOut = amountIn;

        while (data.length > 0) {
            (, Action action) = abi.decode(data, (bytes, Action));
            if (action == Action.UNISWAPV2) {
                amountOut = uniswapV2(amountOut, data);
            } else if (action == Action.UNISWAPV3) {
                amountOut = uniswapV3(amountOut, data);
            } else if (action == Action.RETRO) {
                amountOut = retro(amountOut, data);
            } else if (action == Action.PEARL) {
                amountOut = pearl(amountOut, data);
            } else if (action == Action.QUICKSWAPV2) {
                amountOut = quickswapV2(amountOut, data);
            } else if (action == Action.QUICKSWAPV3) {
                amountOut = quickswapV3(amountOut, data);
            } else if (action == Action.KYBERSWAP) {
                amountOut = kyberswap(amountOut, data);
            } else if (action == Action.SUSHISWAPV2) {
                amountOut = sushiswapV2(amountOut, data);
            } else {
                revert InvalidAction(action);
            }

            (data) = abi.decode(data, (bytes));
        }

        if (amountOut < amountOutMin) {
            revert AmountOutMinNotReached(amountOut, amountOutMin);
        }

        IERC20(tokenOut).transfer(msg.sender, amountOut);
    }

    function uniswapV2(uint256 amountIn, bytes memory data) internal returns (uint256 amountOut) {
        (, , address tokenIn, address tokenOut) = abi.decode(data, (bytes, Action, address, address));
        IERC20(tokenIn).approve(0xedf6066a2b290C185783862C7F4776A2C8077AD1, amountIn);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amounts = IUniswapV2(0xedf6066a2b290C185783862C7F4776A2C8077AD1).swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0,
            path: path,
            to: address(this),
            deadline: block.timestamp
        });
        amountOut = amounts[amounts.length - 1];
    }

    function uniswapV3(uint256 amountIn, bytes memory data) internal returns (uint256 amountOut) {
        (, , address tokenIn, address tokenOut, uint24 fee) = abi.decode(data, (bytes, Action, address, address, uint24));
        IERC20(tokenIn).approve(0xE592427A0AEce92De3Edee1F18E0157C05861564, amountIn);
        amountOut = IUniswapV3(0xE592427A0AEce92De3Edee1F18E0157C05861564).exactInputSingle(
            IUniswapV3.ExactInputSingleParams({
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

    function kyberswap(uint256 amountIn, bytes memory data) internal returns (uint256 amountOut) {
        (, , address tokenIn, address tokenOut, uint24 fee) = abi.decode(data, (bytes, Action, address, address, uint24));
        IERC20(tokenIn).approve(0xF9c2b5746c946EF883ab2660BbbB1f10A5bdeAb4, amountIn);
        amountOut = IKyberswap(0xF9c2b5746c946EF883ab2660BbbB1f10A5bdeAb4).swapExactInputSingle(
            IKyberswap.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                minAmountOut: 0,
                limitSqrtP: 0
            })
        );
    }

    function retro(uint256 amountIn, bytes memory data) internal returns (uint256 amountOut) {
        (, , address tokenIn, address tokenOut, uint24 fee) = abi.decode(data, (bytes, Action, address, address, uint24));
        IERC20(tokenIn).approve(0x1891783cb3497Fdad1F25C933225243c2c7c4102, amountIn);
        amountOut = IUniswapV3(0x1891783cb3497Fdad1F25C933225243c2c7c4102).exactInputSingle(
            IUniswapV3.ExactInputSingleParams({
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

    function quickswapV2(uint256 amountIn, bytes memory data) internal returns (uint256 amountOut) {
        (, , address tokenIn, address tokenOut) = abi.decode(data, (bytes, Action, address, address));
        IERC20(tokenIn).approve(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff, amountIn);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amounts = IUniswapV2(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff).swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0,
            path: path,
            to: address(this),
            deadline: block.timestamp
        });
        amountOut = amounts[amounts.length - 1];
    }

    function quickswapV3(uint256 amountIn, bytes memory data) internal returns (uint256 amountOut) {
        (, , address tokenIn, address tokenOut, uint24 fee) = abi.decode(data, (bytes, Action, address, address, uint24));
        IERC20(tokenIn).approve(0xf5b509bB0909a69B1c207E495f687a596C168E12, amountIn);
        amountOut = IUniswapV3(0xf5b509bB0909a69B1c207E495f687a596C168E12).exactInputSingle(
            IUniswapV3.ExactInputSingleParams({
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

    function pearl(uint256 amountIn, bytes memory data) internal returns (uint256 amountOut) {
        (, , address tokenIn, address tokenOut, bool stable) = abi.decode(data, (bytes, Action, address, address, bool));
        IERC20(tokenIn).approve(0xcC25C0FD84737F44a7d38649b69491BBf0c7f083, amountIn);
        uint256[] memory amounts = IPearl(0xcC25C0FD84737F44a7d38649b69491BBf0c7f083).swapExactTokensForTokensSimple({
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

    function sushiswapV2(uint256 amountIn, bytes memory data) internal returns (uint256 amountOut) {
        (, , address tokenIn, address tokenOut) = abi.decode(data, (bytes, Action, address, address));
        IERC20(tokenIn).approve(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506, amountIn);
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256[] memory amounts = IUniswapV2(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506).swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: 0,
            path: path,
            to: address(this),
            deadline: block.timestamp
        });
        amountOut = amounts[amounts.length - 1];
    }
}
