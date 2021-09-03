import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import { ethers } from "hardhat";

import * as utils from "./utils";
import * as constants from "./constants";

async function main() {
  // if only readonly txes can use a provider instead
  const [signer] = await ethers.getSigners();

  let lootContract = utils.contractFromCompiled(
    constants.LOOT_MAIN_ADDR,
    "Loot"
  );
  console.log((await lootContract.totalSupply()).toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
