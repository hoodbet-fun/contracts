// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPrizePool} from "../../src/interfaces/IPrizePool.sol";

/// @dev Mirrors PT V5: tokens must be transferred to the pool before contributePrizeTokens.
contract MockPrizePool is IPrizePool {
  IERC20 public immutable token;
  uint256 public accountedBalance;
  mapping(address vault => uint256 amount) public contributions;

  error ContributionGTDeltaBalance(uint256 amount, uint256 available);

  constructor(address prizeToken_) {
    token = IERC20(prizeToken_);
  }

  function prizeToken() external view returns (address) {
    return address(token);
  }

  function contributePrizeTokens(address vault, uint256 amount) external {
    uint256 delta = token.balanceOf(address(this)) - accountedBalance;
    if (delta < amount) {
      revert ContributionGTDeltaBalance(amount, delta);
    }
    contributions[vault] += amount;
    accountedBalance += amount;
  }
}
