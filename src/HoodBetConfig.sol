// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title HoodBetConfig
/// @notice Canonical addresses for hoodbet.fun on Robinhood Chain mainnet (chain ID 4663).
library HoodBetConfig {
  uint256 internal constant CHAIN_ID = 4663;
  uint256 internal constant TESTNET_CHAIN_ID = 46630;

  address internal constant SAFE_OWNER = 0x5FF989aCB81e612fb54d2BDE9C6334B4C9a8f117;
  address internal constant MORPHO_VAULT = 0xDF06045aBAE69d6e73a7F0197FED917032d22194;
  address internal constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;

  uint256 internal constant DRAW_PERIOD_SECONDS = 1 days;
  uint256 internal constant NUMBER_OF_TIERS = 4;
  uint256 internal constant GRAND_PRIZE_PERIOD_DRAWS = 91;
}
