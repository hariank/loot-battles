// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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

contract LootBattler is Context, Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

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

  function claimFunds(uint256 amount) external nonReentrant {
    _releaseFunds(_msgSender(), amount);
  }

  /// @notice Creates a challenge for the user but first checks that they own the loot, have enough of the token,
  /// and that the loot isn't currently actively being used in a challenge.
  /// @param challengerLootId The loot id the user is using in the challenge
  /// @param wagerAmount The amount of AGLD tokens the user is wagering
  function createChallenge(uint256 challengerLootId, uint256 wagerAmount)
    external
    nonReentrant
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

    _escrowFunds(_msgSender(), wagerAmount);

    _challenges.push(
      Challenge({
        challengerAddress: _msgSender(),
        lootId: challengerLootId,
        wagerAmount: wagerAmount
      })
    );
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
  ) external nonReentrant {
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

    // Transfer winnings from loser to winner
    _balances[winnerAddress] += winnings;
    _balances[loserAddress] -= winnings;

    // Delete challenge and mark loots as inactive
    if (challengeIdx < challengesSize - 1) {
      _challenges[challengeIdx] = _challenges[challengesSize - 1];
    }
    _challenges.pop();
    delete _activeByLootIdMap[challenge.lootId];
  }

  /// @notice If a valid active challenge exists for the given sender and loot id, delete it.
  /// @param lootId The id of the loot the user wagered
  function deleteChallenge(uint256 lootId) external nonReentrant {
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

    // return the wager to user balance and make loot inactive
    _balances[_msgSender()] += challenge.wagerAmount;
    delete _activeByLootIdMap[lootId];
  }

  /// @notice Deposit user wager amount. Note that we don't update balances unless
  //  the user deletes challenge or a battle happens
  function _escrowFunds(address wagerer, uint256 amount) internal {
    agldContract.safeTransferFrom(wagerer, address(this), amount);
  }

  function _releaseFunds(address claimer, uint256 amount) internal {
    require(_balances[claimer] >= amount);
    agldContract.safeTransferFrom(address(this), claimer, amount);
    _balances[claimer] -= amount;
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
