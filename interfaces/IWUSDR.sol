// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";

interface IWUSDR is IERC20 {
    function previewDeposit(uint256 assets) external pure returns (uint256);

    function deposit(
        uint256 assets,
        address receiver
    ) external returns (uint256 shares);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function redeem(
        uint256 amount,
        address from,
        address to
    ) external returns (uint256 assets);
}
