// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRng — PoolTogether V5 draw manager RNG interface
interface IRng {
  function requestedAtBlock(uint32 rngRequestId) external returns (uint256);
  function isRequestComplete(uint32 rngRequestId) external view returns (bool);
  function isRequestFailed(uint32 rngRequestId) external view returns (bool);
  function randomNumber(uint32 rngRequestId) external returns (uint256);
}
