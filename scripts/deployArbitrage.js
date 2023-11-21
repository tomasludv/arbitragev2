const { ethers } = require("hardhat");

async function main() {
    console.log("deploying...");
    const factory = await ethers.getContractFactory("Arbitrage");
    const contract = await factory.deploy();

    await contract.waitForDeployment();

    console.log("Arbitrage contract deployed: ", contract.target);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});