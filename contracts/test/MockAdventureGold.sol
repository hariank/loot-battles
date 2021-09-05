// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockAdventureGold is ERC20 {
  constructor() ERC20("Adventure Gold", "AGLD") {}

  function mint(uint256 amount) external {
    _mint(msg.sender, amount);
  }
}
