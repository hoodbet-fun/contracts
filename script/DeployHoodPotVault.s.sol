// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {HoodBetConfig} from "../src/HoodBetConfig.sol";
import {
  IPrizePoolMinimal,
  IPrizeVaultFactory,
  IPrizeVaultMinimal,
  ITpdaLiquidationPairFactory
} from "../src/interfaces/IPrizeVaultFactory.sol";

/// @notice Redeploy HoodPot PrizeVault with yield buffer + liquidation pair wiring.
contract DeployHoodPotVault is Script {
  address internal constant PRIZE_POOL = 0x14E5004A757A85439Fc379C8AcD5b3b3CDF47344;
  address internal constant CLAIMER = 0x71ec0971e8f8E35568A4bbe0fc118E6CA0ebe707;
  address internal constant FACTORY = 0xa81B8281586115a228763A584734325BEb71E5c2;
  address internal constant LP_FACTORY = 0x00049FcE2De06310805693b00b63755cA6B22Fe7;

  uint64 internal constant TARGET_AUCTION_PERIOD = 86_400;
  uint192 internal constant TARGET_AUCTION_PRICE = 1_000_000; // 1 USDG
  uint256 internal constant SMOOTHING_FACTOR = 0.1e18;

  function run() external {
    uint256 yieldBuffer = vm.envOr("YIELD_BUFFER", uint256(500_000));
    bool transferToSafe = vm.envOr("TRANSFER_OWNERSHIP_TO_SAFE", true);

    IERC20 usdg = IERC20(HoodBetConfig.USDG);
    IPrizeVaultFactory factory = IPrizeVaultFactory(FACTORY);

    require(usdg.balanceOf(msg.sender) >= yieldBuffer, "insufficient USDG for yield buffer");

    vm.startBroadcast();

    usdg.approve(FACTORY, yieldBuffer);

    address vault = factory.deployVault(
      "HoodPot",
      "hpUSDG",
      IERC4626(HoodBetConfig.MORPHO_VAULT),
      PRIZE_POOL,
      CLAIMER,
      address(0),
      0,
      yieldBuffer,
      msg.sender
    );

    address pair = ITpdaLiquidationPairFactory(LP_FACTORY).createPair(
      vault,
      HoodBetConfig.USDG,
      IPrizePoolMinimal(PRIZE_POOL).prizeToken(),
      TARGET_AUCTION_PERIOD,
      TARGET_AUCTION_PRICE,
      SMOOTHING_FACTOR
    );

    IPrizeVaultMinimal(vault).setLiquidationPair(pair);

    if (transferToSafe) {
      IPrizeVaultMinimal(vault).transferOwnership(HoodBetConfig.SAFE_OWNER);
    }

    vm.stopBroadcast();

    _assertVault(vault, yieldBuffer);

    console2.log("HoodPot PrizeVault", vault);
    console2.log("LiquidationPair", pair);
    console2.log("yieldBuffer", yieldBuffer);
  }

  function _assertVault(address vault, uint256 yieldBuffer) internal view {
    IPrizeVaultMinimal v = IPrizeVaultMinimal(vault);
    IPrizeVaultFactory factory = IPrizeVaultFactory(FACTORY);

    require(factory.deployedVaults(vault), "vault not in factory");
    require(v.yieldBuffer() == yieldBuffer, "yieldBuffer mismatch");
    require(v.yieldVault() == HoodBetConfig.MORPHO_VAULT, "yieldVault mismatch");
    require(v.prizePool() == PRIZE_POOL, "prizePool mismatch");
    require(v.owner() == HoodBetConfig.SAFE_OWNER, "owner not Safe");
  }
}
