require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-ethers");
require("hardhat-gas-reporter");
require("hardhat-tracer");

// make sure process env is ready
require("dotenv").config();

module.exports = {
  solidity: "0.8.16",
  defaultNetwork: "hardhat",
  solidity: {
    compilers: [
      {
        version: "0.8.16",
        settings: {
          optimizer: { // Keeps the amount of gas used in check
            enabled: true,
            runs: 100000
          }
        }
      },
    ],
  },
  networks: {
    hardhat: {
      chainId: 31337,
      gas: "auto",
      gasPrice: "auto",
      saveDeployments: false,
      forking: {
        url: `https://eth-rinkeby.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      },
    },
  },
  gasReporter: {
    currency: 'USD',
    gasPrice: 20,
    coinmarketcap: '9896bb6e-1429-4e65-8ba8-eb45302f849b',
    showMethodSig: true,
    showTimeSpent: true,
    enabled: true
  },
};
