// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
  IERC20 public agldContract;
  ILootComponents public lootComponents;

  struct Challenge {
    address challengerAddress;
    uint256 lootId;
    uint256 wagerAmount;
  }

  // open challenges
  Challenge[] private _challenges;

  // map of loot ids to whether they are in use or not
  mapping(uint256 => bool) private _activeByLootIdMap;

  // deposits and winnings
  mapping(address => uint256) private _balances;

  // Official loot contract is available at https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7
  constructor(
    address _lootContractAddress,
    address _agldTokenAddress,
    address _lootComponentsAddress
  ) Ownable() {
    lootContract = IERC721Enumerable(_lootContractAddress);
    agldContract = IERC20(_agldTokenAddress);
    lootComponents = ILootComponents(_lootComponentsAddress);
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  /// @notice Creates a challenge for the user but first checks that they own the loot, have enough of the token,
  /// and that the loot isn't currently actively being used in a challenge.
  /// @param challengerLootId The loot id the user is using in the challenge
  /// @param wagerAmount The amount of AGLD tokens the user is wagering
  function createChallenge(uint256 challengerLootId, uint256 wagerAmount)
    external
  {
    require(_userOwnsLoot(_msgSender(), challengerLootId), "MUST_OWN_LOOT");
    require(
      _userHasWagerAmount(_msgSender(), wagerAmount),
      "MUST_OWN_ENOUGH_TOKENS"
    );
    require(
      _activeByLootIdMap[challengerLootId] != true,
      "LOOT_MUST_NOT_BE_ACTIVE"
    );

    // Mark challenger's loot id as active.
    _activeByLootIdMap[challengerLootId] = true;

    _challenges.push(
      Challenge({
        challengerAddress: _msgSender(),
        lootId: challengerLootId,
        wagerAmount: wagerAmount
      })
    );

    // TODO: Transfer money from user to escrow
  }

  /// @notice Lets a user accept a pending challenge and first verifies that the state is valid (users own enough
  /// tokens, own the loot, etc). Executes the battle, determines the winner, and then transfers the earnings out.
  /// Both challengerAddress & challengerLootId are used to find the ongoing challenge in _challenges.
  /// @param accepterLootID The address of the user in the challenge
  /// @param challengerAddress The address of the the challenger this user wants to fight
  /// @param challengerLootId The id of the loot the user wants to fight
  function acceptChallenge(
    uint256 accepterLootID,
    address challengerAddress,
    uint256 challengerLootId
  ) external {
    require(_userOwnsLoot(_msgSender(), accepterLootID), "MUST_OWN_LOOT");
    require(
      _activeByLootIdMap[accepterLootID] != true,
      "LOOT_MUST_NOT_BE_ACTIVE"
    );

    // Find the challenge if it exists
    Challenge memory challenge;
    bool foundChallenge = false;
    uint256 challengeIdx;
    uint256 challengesSize = _challenges.length;
    for (uint256 i = 0; i < challengesSize; i++) {
      challenge = _challenges[i];
      if (
        challenge.challengerAddress == challengerAddress &&
        challenge.lootId == challengerLootId
      ) {
        challengeIdx = i;
        foundChallenge = true;
        break;
      }
    }
    require(foundChallenge, "NO_EXISTING_CHALLENGE");

    // Run validation checks on original challenger again
    require(
      _userOwnsLoot(challenge.challengerAddress, challenge.lootId),
      "MUST_OWN_LOOT"
    );
    require(
      _userHasWagerAmount(challenge.challengerAddress, challenge.wagerAmount),
      "CHALLENGER_MUST_OWN_ENOUGH_TOKENS"
    );
    require(
      _activeByLootIdMap[challenge.lootId] != true,
      "LOOT_MUST_NOT_BE_ACTIVE"
    );

    // Run validation checks on person accepting the challenge
    uint256 accepterWagerAmount = challenge.wagerAmount * 1;
    require(
      _userHasWagerAmount(challenge.challengerAddress, accepterWagerAmount),
      "MUST_OWN_ENOUGH_TOKENS"
    );

    // Mark accepter's loot as active
    _activeByLootIdMap[accepterLootID] = true;

    uint256 winningLootId = _battle(challenge.lootId, accepterLootID);
    address winnerAddress;
    address loserAddress;
    uint256 winnings;
    if (winningLootId == challenge.lootId) {
      winnerAddress = challenge.challengerAddress;
      loserAddress = _msgSender();
      winnings = challenge.wagerAmount;
    } else {
      winnerAddress = _msgSender();
      loserAddress = challenge.challengerAddress;
      winnings = accepterWagerAmount;
    }

    // TODO: Transfer money from loser to the winner

    // Delete challenge and mark loots as inactive
    if (challengeIdx < challengesSize - 1) {
      _challenges[challengeIdx] = _challenges[challengesSize - 1];
    }
    _challenges.pop();
    delete _activeByLootIdMap[challenge.lootId];
    delete _activeByLootIdMap[accepterLootID];
  }

  /// @notice If a valid active challenge exists for the given sender and loot id, delete it.
  /// @param lootId The id of the loot the user wagered
  function deleteChallenge(uint256 lootId) external {
    require(_userOwnsLoot(_msgSender(), lootId), "MUST_OWN_LOOT");
    require(_activeByLootIdMap[lootId] == true, "LOOT_MUST_BE_ACTIVE");

    // Find the challenge if it exists
    Challenge memory challenge;
    bool foundChallenge = false;
    uint256 challengeIdx;
    uint256 challengesSize = _challenges.length;
    for (uint256 i = 0; i < challengesSize; i++) {
      challenge = _challenges[i];
      if (
        challenge.challengerAddress == _msgSender() &&
        challenge.lootId == lootId
      ) {
        challengeIdx = i;
        foundChallenge = true;
        break;
      }
    }
    require(foundChallenge, "NO_EXISTING_CHALLENGE");

    if (challengeIdx < challengesSize - 1) {
      _challenges[challengeIdx] = _challenges[challengesSize - 1];
    }
    _challenges.pop();
    delete _activeByLootIdMap[lootId];

    // TODO: Transfer money back to user
  }

  /// @notice Computes the power of both opponents' loot items and executes a random function that determines the
  /// winner of the battle. The winning loot id is returned.
  /// @param challengerLootId The id of the loot the person who created the challenge is using
  /// @param accepterLootId The id of the loot the person who accepted is using
  function _battle(uint256 challengerLootId, uint256 accepterLootId)
    internal
    pure
    returns (uint256)
  {
    uint256 challengerLootPower = _computeLootPower(challengerLootId);
    uint256 accepterLootPower = _computeLootPower(accepterLootId);

    // TODO: Implement actual battle logic
    return
      challengerLootPower >= accepterLootPower
        ? challengerLootId
        : accepterLootId;
  }

  /// @notice Given a lootId, this function computes the overall power of the loot that will then be used
  /// in the battle
  /// @param lootId The id of the loot the user is wagering
  function _computeLootPower(uint256 lootId) internal pure returns (uint256) {
    return 0;
  }

  /// @notice Checks if the user in the battle with the loot actually owns it
  /// @param userAddress The address of the user in the challenge
  /// @param lootId The id of the loot the user is wagering
  function _userOwnsLoot(address userAddress, uint256 lootId)
    internal
    view
    returns (bool)
  {
    return userAddress == lootContract.ownerOf(lootId);
  }

  /// @notice Checks if the user wagering a certain amount of AGLD actually has enough to go through
  /// @param userAddress The address of the user in the challenge
  /// @param wagerAmount The amount of AGLD tokens the user is wagering
  function _userHasWagerAmount(address userAddress, uint256 wagerAmount)
    internal
    view
    returns (bool)
  {
    return agldContract.balanceOf(userAddress) >= wagerAmount;
  }
}
