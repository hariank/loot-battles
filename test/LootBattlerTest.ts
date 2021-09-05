import { assert, expect } from "chai";
import { BigNumber, Contract, Signer } from "ethers";
import { ethers, network } from "hardhat";
import * as utils from "../scripts/utils";

const ADDRESSES: Record<string, string> = {
  LOOT_OWNER_1: "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266",
  LOOT_OWNER_2: "0x70997970c51812dc3a010c7d01b50e0d17dc79c8",
  OTHER_OWNER: "0x90f79bf6eb2c4f870365e785982e1f101e93b906",
  ZERO: "0x0000000000000000000000000000000000000000",
};
const TOKEN_IDS: Record<string, number> = {
  LOOT_1: 1,
  LOOT_2: 2,
  LOOT_3: 3,
};

async function impersonateSigner(account: string): Promise<Signer> {
  // Impersonate account
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [account],
  });

  // Return ethers signer
  return ethers.provider.getSigner(account);
}

let Signer_1: Signer;
let Signer_2: Signer;

let Battler_1: Contract;
let Battler_2: Contract;

let Loot: Contract;
let LootComponents: Contract;
let AdventureGold: Contract;
let LootBattler: Contract;

async function deployAll(): Promise<void> {
  Loot = await utils.deployContractFromCompiled("Loot");
  LootComponents = await utils.deployContractFromCompiled("LootComponents");
  AdventureGold = await utils.deployContractFromCompiled("MockAdventureGold");
  LootBattler = await utils.deployContractFromCompiled(
    "LootBattler",
    Loot.address,
    AdventureGold.address,
    LootComponents.address
  );
}

describe("LootBattler", function () {
  beforeEach(async () => {
    // deploy all contracts
    await deployAll();

    // signers
    Signer_1 = await impersonateSigner(ADDRESSES.LOOT_OWNER_1);
    Signer_2 = await impersonateSigner(ADDRESSES.LOOT_OWNER_2);

    // connect signers
    Battler_1 = LootBattler.connect(Signer_1);
    Battler_2 = LootBattler.connect(Signer_2);

    // starter loot
    await Loot.connect(Signer_1).claim(TOKEN_IDS.LOOT_1);
    await Loot.connect(Signer_2).claim(TOKEN_IDS.LOOT_2);

    // starter agld
    const agld_1 = AdventureGold.connect(Signer_1);
    const agld_2 = AdventureGold.connect(Signer_2);
    await agld_1.mint(5000);
    await agld_2.mint(10000);

    // agld allowances
    await agld_1.approve(ADDRESSES.LOOT_OWNER_1, 100000);
    await agld_2.approve(ADDRESSES.LOOT_OWNER_2, 100000);
    await agld_1.approve(LootBattler.address, 100000);
    await agld_2.approve(LootBattler.address, 100000);
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

  it("initial agld", async function () {
    assert.equal(await AdventureGold.balanceOf(ADDRESSES.LOOT_OWNER_1), 5000);
    assert.equal(await AdventureGold.balanceOf(ADDRESSES.LOOT_OWNER_2), 10000);
  });

  describe("deposits and withdrawals", function () {
    it("initial battle balance", async function () {
      assert.equal(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_1), 0);
      assert.equal(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_2), 0);
    });

    it("deposit but insufficient tokens", async function () {
      await expect(Battler_1.depositFunds(6000)).to.be.revertedWith(
        "ERC20: transfer amount exceeds balance"
      );
    });

    it("deposit", async function () {
      await Battler_1.depositFunds(100);
      assert.equal(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_1), 100);
      assert.equal(
        await AdventureGold.balanceOf(ADDRESSES.LOOT_OWNER_1),
        5000 - 100
      );
    });

    it("withdraw too much", async function () {
      await Battler_1.depositFunds(100);
      await expect(Battler_1.claimFunds(200)).to.be.revertedWith(
        "INSUFFICIENT_BALANCE"
      );
    });

    it("withdraw", async function () {
      await Battler_1.depositFunds(100);
      await Battler_1.claimFunds(50);
      assert.equal(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_1), 50);
      assert.equal(
        await AdventureGold.balanceOf(ADDRESSES.LOOT_OWNER_1),
        5000 - 100 + 50
      );
    });
  });

  describe("create challenges", function () {
    beforeEach(async () => {
      // deposit balances
      await Battler_1.depositFunds(5000);
      await Battler_2.depositFunds(10000);
    });

    it("battle balance", async function () {
      assert.equal(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_1), 5000);
      assert.equal(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_2), 10000);
    });

    it("create challenge user doesn't own loot", async function () {
      await expect(
        Battler_2.createChallenge(TOKEN_IDS.LOOT_1, 10000)
      ).to.be.revertedWith("MUST_OWN_LOOT");
    });

    it("create challenge wager amt too high", async function () {
      await expect(
        Battler_1.createChallenge(TOKEN_IDS.LOOT_1, 10000)
      ).to.be.revertedWith("INSUFFICIENT_BALANCE");
    });

    it("create challenge loot is already active in challenge", async function () {
      await Battler_1.createChallenge(TOKEN_IDS.LOOT_1, 3000);
      await expect(
        Battler_1.createChallenge(TOKEN_IDS.LOOT_1, 100)
      ).to.be.revertedWith("LOOT_MUST_NOT_BE_ACTIVE");
    });

    it("create challenge user 1", async function () {
      await Battler_1.createChallenge(TOKEN_IDS.LOOT_1, 3000);

      // check balance
      expect(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_1)).to.equal(
        5000 - 3000
      );

      // check created challenge
      const [challenge] = await LootBattler.getOpenChallenges();
      expect(challenge.challengerAddress.toLowerCase()).to.equal(
        ADDRESSES.LOOT_OWNER_1
      );
      expect(challenge.lootId).to.equal(TOKEN_IDS.LOOT_1);
      expect(challenge.wagerAmount).to.equal(3000);
    });
  });

  describe("delete challenges", function () {
    beforeEach(async () => {
      // deposit balances
      await Battler_1.depositFunds(500);
      await Battler_2.depositFunds(1000);

      // create initial challenges
      await Battler_1.createChallenge(TOKEN_IDS.LOOT_1, 200);
      await Battler_2.createChallenge(TOKEN_IDS.LOOT_2, 100);
    });

    it("delete challenge inactive loot", async function () {
      await expect(
        Battler_2.deleteChallenge(TOKEN_IDS.LOOT_3)
      ).to.be.revertedWith("LOOT_MUST_BE_ACTIVE");
    });

    it("delete challenge user doesn't own loot", async function () {
      await expect(
        Battler_2.deleteChallenge(TOKEN_IDS.LOOT_1)
      ).to.be.revertedWith("MUST_OWN_LOOT");
    });

    it("delete challenge", async function () {
      await Battler_2.deleteChallenge(TOKEN_IDS.LOOT_2);

      // loot 2 challenge should be deleted
      const [challenge] = await LootBattler.getOpenChallenges();
      expect(challenge.lootId).to.equal(TOKEN_IDS.LOOT_1);

      // check new balance
      expect(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_2)).to.equal(
        1000
      );
    });
  });

  describe("accept challenges", function () {
    beforeEach(async () => {
      // deposit balances
      await Battler_1.depositFunds(500);
      await Battler_2.depositFunds(1000);

      // create initial challenges
      await Battler_1.createChallenge(TOKEN_IDS.LOOT_1, 200);
      await Battler_2.createChallenge(TOKEN_IDS.LOOT_2, 100);
    });

    it("accept challenge user doesn't own loot", async function () {
      await expect(
        Battler_1.acceptChallenge(
          TOKEN_IDS.LOOT_2,
          ADDRESSES.LOOT_OWNER_1,
          TOKEN_IDS.LOOT_2
        )
      ).to.be.revertedWith("MUST_OWN_LOOT");
    });

    it("accept challenge invalid challenger address", async function () {
      await expect(
        Battler_1.acceptChallenge(
          TOKEN_IDS.LOOT_1,
          ADDRESSES.OTHER_OWNER,
          TOKEN_IDS.LOOT_2
        )
      ).to.be.revertedWith("NO_EXISTING_CHALLENGE");
    });

    it("accept challenge invalid challenger loot id", async function () {
      await expect(
        Battler_1.acceptChallenge(
          TOKEN_IDS.LOOT_1,
          ADDRESSES.LOOT_OWNER_2,
          TOKEN_IDS.LOOT_3
        )
      ).to.be.revertedWith("NO_EXISTING_CHALLENGE");
    });

    it("accept challenge insufficient agld to match wager amt", async function () {
      await Battler_1.claimFunds(250);
      await expect(
        Battler_1.acceptChallenge(
          TOKEN_IDS.LOOT_1,
          ADDRESSES.LOOT_OWNER_2,
          TOKEN_IDS.LOOT_2
        )
      ).to.be.revertedWith("INSUFFICIENT_BALANCE");
    });

    it("accept challenge", async function () {
      await Battler_1.acceptChallenge(
        TOKEN_IDS.LOOT_1,
        ADDRESSES.LOOT_OWNER_2,
        TOKEN_IDS.LOOT_2
      );

      // check new balances
      expect(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_1)).to.equal(
        500 - 200 - 100
      );
      expect(await LootBattler.balanceOf(ADDRESSES.LOOT_OWNER_2)).to.equal(
        1000 - 100 + 100
      );

      // loot 2 challenge should be deleted
      const [challenge] = await LootBattler.getOpenChallenges();
      expect(challenge.lootId).to.equal(TOKEN_IDS.LOOT_1);
    });
  });
});
