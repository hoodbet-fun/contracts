// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

/// @notice Minimal PoolTogether V5 PrizePool interface for prize contributions.
interface IPrizePool {
    function contributePrizeTokens(address _vault, uint256 _amount) external;
    function prizeToken() external view returns (address);
}
