/**
 * @type import('hardhat/config').HardhatUserConfig
 */

import * as dotenv from "dotenv";
dotenv.config();

import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-abi-exporter";
import { task } from "hardhat/config";
import { ethers } from "hardhat";
import { HardhatUserConfig } from "hardhat/config";

export function forknet() {
  return {
    url: process.env.RPC_URL_MAINNET,
    blockNumber: 13135486,
  };
}

const config: HardhatUserConfig = {
  solidity: "0.8.0",
  networks: {
    hardhat: {
      forking: forknet(),
    },
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
