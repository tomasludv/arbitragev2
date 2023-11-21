// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";
import {IUniswapRouter} from "../interfaces/IUniswapRouter.sol";

contract UniswapRouter is IUniswapRouter {
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut) {
        IERC20(params.tokenIn).transferFrom(
            msg.sender,
            address(this),
            params.amountIn
        );
        IERC20(params.tokenOut).transfer(msg.sender, params.amountOutMinimum);
        return params.amountOutMinimum;
    }
}
