// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";

interface IPrizePoolMinimal {
  function drawPeriodSeconds() external view returns (uint256);
  function prizeToken() external view returns (address);
}

interface IPrizeVaultMinimal {
  function setLiquidationPair(address _liquidationPair) external;
  function transferOwnership(address newOwner) external;
  function yieldBuffer() external view returns (uint256);
  function maxDeposit(address receiver) external view returns (uint256);
  function yieldVault() external view returns (address);
  function prizePool() external view returns (address);
  function owner() external view returns (address);
}

interface IPrizeVaultFactory {
  function deployVault(
    string memory name,
    string memory symbol,
    IERC4626 yieldVault,
    address prizePool,
    address claimer,
    address yieldFeeRecipient,
    uint32 yieldFeePercentage,
    uint256 yieldBuffer,
    address owner
  ) external returns (address vault);

  function deployedVaults(address vault) external view returns (bool);
}

interface ITpdaLiquidationPairFactory {
  function createPair(
    address source,
    address tokenIn,
    address tokenOut,
    uint64 targetAuctionPeriod,
    uint192 targetAuctionPrice,
    uint256 smoothingFactor
  ) external returns (address pair);
}
