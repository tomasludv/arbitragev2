require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [{ version: "0.8.10" }, { version: "0.8.20" }],
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_ENDPOINT,
      accounts: [process.env.SEPOLIA_PRIVATE_KEY]
    },
    polygon: {
      url: process.env.POLYGON_ENDPOINT,
      accounts: [process.env.POLYGON_PRIVATE_KEY]
    }
  },
};
