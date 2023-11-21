const { ethers } = require("hardhat");

const aavePoolAddressProvider = "0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb";

async function main() {
    console.log("deploying...");
    const factory = await ethers.getContractFactory("FlashLoan3");
    const contract = await factory.deploy(aavePoolAddressProvider);

    await contract.waitForDeployment();

    console.log("Flash loan contract deployed: ", contract.target);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});