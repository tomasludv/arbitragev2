const { ethers } = require("hardhat");

const kyberswapRouter = "0x6131B5fae19EA4f9D964eAc0408E4408b66337b5";
const aavePoolAddressProvider = "0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb";

async function main() {
    console.log("deploying...");
    const factory = await ethers.getContractFactory("FlashLoan2");
    const contract = await factory.deploy(kyberswapRouter, aavePoolAddressProvider);

    await contract.waitForDeployment();

    console.log("Flash loan contract deployed: ", contract.target);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});