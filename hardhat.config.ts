/**
 * @type import('hardhat/config').HardhatUserConfig
 */

import * as dotenv from "dotenv";
dotenv.config();

import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import * as ethers from "ethers";
import "hardhat-abi-exporter";
import { task } from "hardhat/config";
import { HardhatUserConfig } from "hardhat/config";

task("balance", "Prints an account's balance")
  .addParam("address", "The account's address")
  .setAction(async (taskArgs, hre) => {
    const provider = hre.ethers.provider;
    const balance = await provider.getBalance(taskArgs.address);
    console.log(ethers.utils.formatEther(balance).toString(), "eth");
  });

export function forknet() {
  return {
    url: process.env.RPC_URL_MAINNET,
    blockNumber: 13163246,
  };
}

const config: HardhatUserConfig = {
  solidity: "0.8.0",
  networks: {
    // hardhat: {
    //   forking: forknet(),
    // },
    testnet: {
      url: process.env.RPC_URL_TESTNET,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    testnet_wss: {
      url: process.env.RPC_WSS_URL_TESTNET,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
    mainnet: {
      url: process.env.RPC_URL_MAINNET,
      accounts: [`0x${process.env.PRIVATE_KEY}`],
    },
  },
  abiExporter: {
    path: "./abis",
    clear: true,
  },
};
export default config;
