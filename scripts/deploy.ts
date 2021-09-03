import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers } from "hardhat";
import { BigNumber, Contract, ContractFactory } from "ethers";

import * as utils from "./utils";
import * as constants from "./constants";

async function main() {
  const [deployer] = await ethers.getSigners();

  let cp: BigNumber = await deployer.getGasPrice();
  console.log("Current gas price: ", cp.toString());
  console.log("Deployer:", deployer.address);
  console.log("Deployer balance:", (await deployer.getBalance()).toString());

  const cf: ContractFactory = await ethers.getContractFactory("LootBattler");
  const c: Contract = await cf.deploy(constants.LOOT_COMPONENTS_ADDR);
  await c.deployed();
  console.log("Contract deployed to:", c.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
