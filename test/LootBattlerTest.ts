import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import { ethers } from "hardhat";
import { expect } from "chai";
import * as constants from "../scripts/constants";
import * as utils from "../scripts/utils";

describe("LootBattler", function () {
  it("balanceOf", async function () {
    const c: Contract = await utils.deployContractFromCompiled(
      "LootBattler",
      constants.LOOT_COMPONENTS_ADDR
    );
    // const Greeter = await ethers.getContractFactory("Greeter");
    // const greeter = await Greeter.deploy("Hello, world!");
    // await greeter.deployed();

    // expect(await greeter.greet()).to.equal("Hello, world!");

    // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");

    // // wait until the transaction is mined
    // await setGreetingTx.wait();

    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});
