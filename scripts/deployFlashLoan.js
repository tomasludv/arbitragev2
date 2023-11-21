const { ethers } = require("hardhat");

const uniswapRouter = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
const quickswapRouter = "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff";
const pearl = "0xcC25C0FD84737F44a7d38649b69491BBf0c7f083";
const aavePoolAddressProvider = "0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb";

async function main() {
  console.log("deploying...");
  const flashLoanFactory = await ethers.getContractFactory("FlashLoan");
  const flashLoanContract = await flashLoanFactory.deploy(uniswapRouter, quickswapRouter, pearl, aavePoolAddressProvider);

  await flashLoanContract.waitForDeployment();

  console.log("Flash loan contract deployed: ", flashLoanContract.target);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});