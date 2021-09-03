/**
 *Submitted for verification at Etherscan.io on 2021-08-30
 */

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface ILootComponents {
  function weaponComponents(uint256 tokenId)
    external
    view
    returns (uint256[5] memory);

  function chestComponents(uint256 tokenId)
    external
    view
    returns (uint256[5] memory);

  function headComponents(uint256 tokenId)
    external
    view
    returns (uint256[5] memory);

  function waistComponents(uint256 tokenId)
    external
    view
    returns (uint256[5] memory);

  function footComponents(uint256 tokenId)
    external
    view
    returns (uint256[5] memory);

  function handComponents(uint256 tokenId)
    external
    view
    returns (uint256[5] memory);

  function neckComponents(uint256 tokenId)
    external
    view
    returns (uint256[5] memory);

  function ringComponents(uint256 tokenId)
    external
    view
    returns (uint256[5] memory);
}

contract LootBattler is Ownable {
  ILootComponents public lootComponents;

  // deposits and winnings
  mapping(address => uint256) private _balances;

  // open challenges
  struct Challenge {
    address challengerId;
    address lootId;
    uint256 wager;
  }
  Challenge[] private challenges;

  constructor(address _lootComponentsAddress) {
    lootComponents = ILootComponents(_lootComponentsAddress);
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  // - check if caller owns loot, enough agld
  // - escrow the agld
  function createChallenge(
    uint256 challengerId,
    uint256 challengerLootId,
    uint256 wagerAmount
  ) external {
    // TODO
  }

  // - check if caller owns loot, enough agld
  // - run the battle
  // 	- update balances
  // 	- send cut to contract
  function acceptChallenge(
    uint256 accepterId,
    uint256 accepterLootId,
    uint256 challengeId
  ) external {
    require(challengeId < challenges.length, "Challenge ID invalid");

    // TODO: Compute wager amount for challenger
    // TODO: Check if accepter owns loot and has enough to wager
    // TODO: Execute battle
    // TODO: Settle
  }

  // Battles the two loots and returns the id of the loot winner
  function battle(uint256 challengerLootId, uint256 accepterLootId)
    internal
    pure
    returns (uint256)
  {
    uint256 challengerLootPower = computeLootPower(challengerLootId);
    uint256 accepterLootPower = computeLootPower(accepterLootId);

    // TODO: Figure out actual challenge logic
    return challengerLootPower >= accepterLootPower;
  }

  // Given the address of a loot, it computes the total power of that loot collection.
  function computeLootPower(uint256 lootId) internal pure returns (unit256) {
    return 0;
  }

  // Check if challenger owns the loot
  function challengerOwnsLoot(uint256 challengerId, uint256 lootId)
    internal
    pure
    returns (bool)
  {
    return true;
  }

  // Check if challenger has enough gold to wager
  function challengerOwnsWagerAmount(uint256 challengerId, uint256 wagerAmount)
    internal
    pure
    returns (bool)
  {
    return true;
  }
}
