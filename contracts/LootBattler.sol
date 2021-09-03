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

  function createChallenge(
    uint256 challengerId,
    uint256 challengerLootId,
    uint256 wagerAmount
  ) external {
    // TODO: Check if challenger owns loot
    // TODO: Check if challenger has enough AGLD
  }

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

  function computeLootPower(uint256 lootId) internal pure returns (unit256) {
    // TODO: Given the address of a loot, compute the total power of that loot.
    return 0;
  }

  function userOwnsLoot(uint256 userId, uint256 lootId)
    internal
    pure
    returns (bool)
  {
    // TODO: Given the address of a loot, check if the user owns it.
    return true;
  }

  function userHasWagerAmount(uint256 userId, uint256 wagerAmount)
    internal
    pure
    returns (bool)
  {
    // TODO: Given a wager amount, check if the user has enough AGLD.
    return true;
  }
}
