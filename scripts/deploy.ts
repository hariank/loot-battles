import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import { ethers } from "hardhat";
import { BigNumber, Contract } from "ethers";

import * as utils from "./utils";
import * as constants from "./constants";

async function logDeployerInfo(deployer) {
  let cp: BigNumber = await deployer.getGasPrice();
  console.log("Current gas price: ", cp.toString());
  console.log("Deployer:", deployer.address);
  console.log("Deployer balance:", (await deployer.getBalance()).toString());
}

async function deployPeripheralContracts() {
  const loot: Contract = await utils.deployContractFromCompiled("Loot");
  const lootAddr = loot.address;
  console.log("Loot contract deployed to:", lootAddr);

  const lootComp: Contract = await utils.deployContractFromCompiled(
    "LootComponents"
  );
  const lootCompAddr = lootComp.address;
  console.log("LootComponents contract deployed to:", lootCompAddr);

  const agld: Contract = await utils.deployContractFromCompiled(
    "AdventureGold",
    lootAddr
  );
  const agldAddr = agld.address;
  console.log("AdventureGold contract deployed to:", agldAddr);

  return [lootAddr, lootCompAddr, agldAddr];
}

async function deployTestnet() {
  const [deployer] = await ethers.getSigners();

  await logDeployerInfo(deployer);

  const [lootAddr, lootCompAddr, agldAddr] = await deployPeripheralContracts();

  const battler: Contract = await utils.deployContractFromCompiled(
    "LootBattler",
    lootAddr,
    agldAddr,
    lootCompAddr
  );
  console.log("LootBattler contract deployed to:", battler.address);
}

async function deployMainnet() {
  const [deployer] = await ethers.getSigners();

  await logDeployerInfo(deployer);

  const battler: Contract = await utils.deployContractFromCompiled(
    "LootBattler",
    constants.LOOT_MAIN_ADDR,
    constants.AGLD_ADDR,
    constants.LOOT_COMPONENTS_ADDR
  );
  console.log("LootBattler contract deployed to:", battler.address);
}

async function main() {
  await deployTestnet();
  // await deployMainnet();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
