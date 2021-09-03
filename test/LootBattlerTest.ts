import { expect } from "chai";
import { BigNumber, Contract, Signer } from "ethers";
import { ethers, network } from "hardhat";
import * as constants from "../scripts/constants";
import * as utils from "../scripts/utils";
import { forknet } from "../hardhat.config";

const LootABI = require("./test_abi/Loot.json");
const ERC20ABI = require("./test_abi/ERC20.json");

let LootBattler: Contract;

const ADDRESSES: Record<string, string> = {
  // https://opensea.io/0x3fae7d59a245527fc09f2c274e18a3834e027708
  OWNER_1: "0x3Fae7D59a245527Fc09F2c274E18A3834E027708",
  // https://opensea.io/0x930af7923b8b5f8d3461ad1999ceeb8a62884b19
  OWNER_2: "0x930af7923b8b5f8d3461ad1999ceeb8a62884b19",
  // Loot contract
  LOOT: "0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7",
  ZERO: "0x0000000000000000000000000000000000000000",
};

const TOKEN_IDS: Record<string, number> = {
  LOOT_ONE: 5726,
  LOOT_TWO: 3686,
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

async function deployBattler(): Promise<void> {
  const c: Contract = await utils.deployContractFromCompiled(
    "LootBattler",
    constants.LOOT_MAIN_ADDR,
    constants.LOOT_COMPONENTS_ADDR,
    constants.AGLD_ADDR
  );

  LootBattler = c;
}

function getAddress(c: Contract): string {
  return c.address.toString();
}

async function approveCoin(amt: number): Promise<void> {
  const signer = await impersonateSigner(ADDRESSES.OWNER_1);
  const agld = await utils.contractFromABI(
    constants.AGLD_ADDR,
    ERC20ABI,
    signer
  );
  await agld.approve(getAddress(LootBattler), amt);
}

describe("LootBattler", function () {
  // Pre-setup
  beforeEach(async () => {
    // Reset hardhat forknet
    await network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: forknet(),
        },
      ],
    });

    // Deploy contract
    await deployBattler();
  });

  describe("AGLD balance", async () => {
    beforeEach(async () => {});

    it("initial winnings", async function () {
      await approveCoin(10000);
      await expect(LootBattler.balanceOf(ADDRESSES.OWNER_1)).equal(0);
    });
  });
});
