require("@nomicfoundation/hardhat-toolbox");

require('dotenv').config();

const privateKey = process.env.VITE_WALLET_PRIVATE_KEY;
const providerUrl = process.env.VITE_ALCHEMY_SEPOLIA_PROVIDER_URL;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    sepolia: {
      url: providerUrl,
      accounts: [privateKey],
    }
  }
};
