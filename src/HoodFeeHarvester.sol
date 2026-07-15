// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPrizePool} from "./interfaces/IPrizePool.sol";

/// @title HoodFeeHarvester
/// @notice Receives Morpho vault fee shares, redeems to underlying, and contributes to the PrizePool.
/// @dev Intended as performanceFeeRecipient + managementFeeRecipient on the Morpho vault.
///      The Safe multisig should own this contract and set prizeVault after PrizeVault deployment.
contract HoodFeeHarvester is Ownable {
  using SafeERC20 for IERC20;

  IPrizePool public immutable prizePool;
  IERC4626 public immutable morphoVault;
  IERC20 public immutable asset;

  /// @notice PrizeVault address registered in PrizePool for contribution accounting.
  address public prizeVault;

  event PrizeVaultSet(address indexed prizeVault);
  event FeesHarvested(uint256 sharesRedeemed, uint256 assetsContributed);

  error PrizeVaultNotSet();
  error ZeroPrizeVault();
  error ZeroShares();
  error AssetMismatch();

  constructor(address _owner, address _prizePool, address _morphoVault) Ownable(_owner) {
    prizePool = IPrizePool(_prizePool);
    morphoVault = IERC4626(_morphoVault);
    asset = IERC20(morphoVault.asset());

    if (address(asset) != prizePool.prizeToken()) {
      revert AssetMismatch();
    }
  }

  /// @notice One-time wiring after PrizeVault is deployed via PrizeVaultFactory.
  function setPrizeVault(address _prizeVault) external onlyOwner {
    if (_prizeVault == address(0)) revert ZeroPrizeVault();
    prizeVault = _prizeVault;
    emit PrizeVaultSet(_prizeVault);
  }

  /// @notice Redeem all Morpho vault shares held by this contract and contribute underlying to the prize pool.
  function harvest() external returns (uint256 assetsContributed) {
    if (prizeVault == address(0)) revert PrizeVaultNotSet();

    uint256 shares = morphoVault.balanceOf(address(this));
    if (shares == 0) revert ZeroShares();

    assetsContributed = morphoVault.redeem(shares, address(this), address(this));

    // PT V5 PrizePool.contributePrizeTokens requires tokens already in the pool (delta balance check).
    asset.safeTransfer(address(prizePool), assetsContributed);
    prizePool.contributePrizeTokens(prizeVault, assetsContributed);

    emit FeesHarvested(shares, assetsContributed);
  }

  /// @notice Morpho fee shares are ERC-20; this contract must be able to receive vault shares.
  function canReceiveShares() external pure returns (bool) {
    return true;
  }
}
