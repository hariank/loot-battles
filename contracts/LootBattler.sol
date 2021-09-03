/**
 *Submitted for verification at Etherscan.io on 2021-08-30
 */

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

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

contract LootBattler is Context, Ownable {
  IERC721Enumerable public lootContract;
  ILootComponents public lootComponents;

  // deposits and winnings
  mapping(address => uint256) private _balances;

  // map of loot ids to whether they are in use or not
  mapping(uint256 => bool) private _activeByLootIdMap;

  // open challenges
  struct Challenge {
    address challengerAddress;
    uint256 lootId;
    uint256 wagerAmount;
  }
  Challenge[] private challenges;

  // Official loot contract is available at https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7
  constructor(address _lootContractAddress, address _lootComponentsAddress)
    Ownable()
  {
    lootContract = IERC721Enumerable(_lootContractAddress);
    lootComponents = ILootComponents(_lootComponentsAddress);
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function createChallenge(uint256 challengerLootId, uint256 wagerAmount)
    external
  {
    // TODO: Check if challenger owns loot
    // TODO: Check if challenger has enough AGLD
    // TODO: Mark loot as active and add to pending challenges
  }

  function acceptChallenge(
    uint256 accepterLootID,
    address challengerAddress,
    uint256 challengerLootId
  ) external {
    // TODO: Fetch challenge if exists
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
    return
      challengerLootPower >= accepterLootPower
        ? challengerLootId
        : accepterLootId;
  }

  function computeLootPower(uint256 lootId) internal pure returns (uint256) {
    // TODO: Given the address of a loot, compute the total power of that loot.
    return 0;
  }

  function userOwnsLoot(address userAddress, uint256 lootId)
    internal
    view
    returns (bool)
  {
    // TODO: Given the address of a loot, check if the user owns it.
    return userAddress == lootContract.ownerOf(lootId);
  }

  function userHasWagerAmount(address userAddress, uint256 wagerAmount)
    internal
    pure
    returns (bool)
  {
    // TODO: Given a wager amount, check if the user has enough AGLD.
    return true;
  }
}
