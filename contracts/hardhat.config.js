require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
  networks: {
    hardhat: {},
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/y6RsMlq62mXqDZC08T_6S", // Replace with your Alchemy key
      accounts: process.env.PRIVATE_KEY ? [`0x${process.env.PRIVATE_KEY}`] : []
    },
    polygon: {
      url: "https://polygon-mainnet.g.alchemy.com/v2/y6RsMlq62mXqDZC08T_6S",
      accounts: process.env.PRIVATE_KEY ? [`0x${process.env.PRIVATE_KEY}`] : []
    }
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY
  }
};