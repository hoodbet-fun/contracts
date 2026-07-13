// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title HoodPointsRegistry
/// @notice On-chain tier verification from $HOOD token balance (Virtuals agent token).
contract HoodPointsRegistry is Ownable {
  IERC20 public immutable hoodToken;

  uint256[4] public tierThresholds;
  string[4] public tierNames = ["Scout", "Hood", "Legend", "OG"];
  uint16[4] public referralMultipliersBps = [10_000, 12_500, 15_000, 20_000];

  event TierThresholdsUpdated(uint256[4] thresholds);

  constructor(address owner_, address hoodToken_, uint256[4] memory thresholds_) Ownable(owner_) {
    hoodToken = IERC20(hoodToken_);
    tierThresholds = thresholds_;
  }

  function setTierThresholds(uint256[4] calldata thresholds_) external onlyOwner {
    tierThresholds = thresholds_;
    emit TierThresholdsUpdated(thresholds_);
  }

  function getTier(address user) external view returns (uint8) {
    uint256 balance = hoodToken.balanceOf(user);
    if (balance >= tierThresholds[3]) return 3;
    if (balance >= tierThresholds[2]) return 2;
    if (balance >= tierThresholds[1]) return 1;
    return 0;
  }

  function getTierName(address user) external view returns (string memory) {
    return tierNames[this.getTier(user)];
  }

  function getReferralMultiplierBps(address user) external view returns (uint16) {
    return referralMultipliersBps[this.getTier(user)];
  }

  function tierThresholdsView() external view returns (uint256[4] memory) {
    return tierThresholds;
  }
}
