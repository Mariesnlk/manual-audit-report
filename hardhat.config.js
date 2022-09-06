require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-solhint");
require("hardhat-gas-reporter");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.7.0",
  gasReporter: {
    enabled: true,
    currency: "USD",
    gasPrice: 160,
    coinmarketcap: process.env.COINT_MARKET_CAP_API
  },
};
