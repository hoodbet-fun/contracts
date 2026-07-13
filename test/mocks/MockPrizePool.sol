// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IPrizePool} from "../../src/interfaces/IPrizePool.sol";

contract MockPrizePool is IPrizePool {
  IERC20 public immutable token;
  mapping(address vault => uint256 amount) public contributions;

  constructor(address prizeToken_) {
    token = IERC20(prizeToken_);
  }

  function prizeToken() external view returns (address) {
    return address(token);
  }

  function contributePrizeTokens(address vault, uint256 amount) external {
    token.transferFrom(msg.sender, address(this), amount);
    contributions[vault] += amount;
  }
}
