// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {Ownable} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/Ownable.sol";
import {IQuickswapRouter} from "../interfaces/IQuickswapRouter.sol";

contract FlashLoan2 is FlashLoanSimpleReceiverBase, Ownable {
    address private immutable kyberswapRouter;

    constructor(
        address _kyberswapRouter,
        address _aavePoolAddressProvider
    )
        FlashLoanSimpleReceiverBase(
            IPoolAddressesProvider(_aavePoolAddressProvider)
        )
    {
        kyberswapRouter = _kyberswapRouter;
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        (
            address tokenIn,
            address tokenOut,
            uint256 amountIn,
            uint256 amountOutMin,
            bytes memory routerDataIn,
            bytes memory routerDataOut
        ) = abi.decode(params, (address, address, uint256, uint256, bytes,bytes));
        uint256 amountOut = kyberswap(tokenIn, amountIn, routerDataIn);
        amountOut = kyberswap(tokenOut, amountOut, routerDataOut);
        require(amountOut >= amountOutMin, "amountOut >= amountOutMin");
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);
        return true;
    }

    function withdraw(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    function arb(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        bytes memory routerDataIn,
        bytes memory routerDataOut
    ) external {
        bytes memory params = abi.encode(
            tokenIn,
            tokenOut,
            amountIn,
            amountOutMin,
            routerDataIn,
            routerDataOut
        );
        POOL.flashLoanSimple(address(this), tokenIn, amountIn, params, 0);
    }

    function kyberswap(
        address tokenIn,
        uint256 amountIn,
        bytes memory routerData
    ) internal returns (uint256 amountOut) {
        IERC20(tokenIn).approve(kyberswapRouter, amountIn);
        (bool success, bytes memory data) = kyberswapRouter.call(routerData);
        require(success, string(data));
        (amountOut, ) = abi.decode(data, (uint256, uint256));
    }
}
