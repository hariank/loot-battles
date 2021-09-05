import { assert, expect } from "chai";
import { BigNumber, Contract, Signer } from "ethers";
import { ethers, network } from "hardhat";
import * as constants from "../scripts/constants";
import * as utils from "../scripts/utils";

const LootABI = require("../abis/contracts/Loot.sol/Loot.json");

const ADDRESSES: Record<string, string> = {
  LOOT_OWNER_1: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
  LOOT_OWNER_2: "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
  ZERO: "0x0000000000000000000000000000000000000000",
};
const TOKEN_IDS: Record<string, number> = {
  LOOT_1: 1,
  LOOT_2: 2,
};

async function impersonateSigner(account: string): Promise<Signer> {
  // Impersonate account
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [account],
  });

  // Return ethers signer
  return await ethers.provider.getSigner(account);
}

let Loot: Contract;
let LootComponents: Contract;
let AdventureGold: Contract;
let LootBattler: Contract;

async function mintLoot(
  address: string,
  lootAddress: string,
  tokenId: number
): Promise<void> {
  const signer = await impersonateSigner(address);
  await (
    await utils.contractFromABI(lootAddress, LootABI, signer)
  ).claim(tokenId);
}

async function deployAll(): Promise<void> {
  Loot = await utils.deployContractFromCompiled("Loot");
  LootComponents = await utils.deployContractFromCompiled("LootComponents");
  AdventureGold = await utils.deployContractFromCompiled("MockAdventureGold");
  LootBattler = await utils.deployContractFromCompiled(
    "LootBattler",
    Loot.address,
    LootComponents.address,
    AdventureGold.address
  );
}

describe("LootBattler", function () {
  beforeEach(async () => {
    // deploy all contracts
    await deployAll();

    // starter loot
    await mintLoot(ADDRESSES.LOOT_OWNER_1, Loot.address, TOKEN_IDS.LOOT_1);
    await mintLoot(ADDRESSES.LOOT_OWNER_2, Loot.address, TOKEN_IDS.LOOT_2);
  });

  it("initial loot", async function () {
    assert.equal(
      (await Loot.ownerOf(TOKEN_IDS.LOOT_1)).toLowerCase(),
      ADDRESSES.LOOT_OWNER_1
    );
    assert.equal(
      (await Loot.ownerOf(TOKEN_IDS.LOOT_2)).toLowerCase(),
      ADDRESSES.LOOT_OWNER_2
    );
  });

  it("initial battle balance", async function () {
    assert.equal(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_1), 0);
    assert.equal(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_2), 0);
  });
});
