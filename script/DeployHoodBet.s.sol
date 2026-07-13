// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {HoodFeeHarvester} from "../src/HoodFeeHarvester.sol";
import {HoodBetConfig} from "../src/HoodBetConfig.sol";

/// @title DeployHoodBet
/// @notice Phase 2 deployment — HoodFeeHarvester after PrizePool is live.
/// @dev Set PRIZE_POOL env var to the deployed PrizePool address.
///      Full PT v5 core deploy uses GenerationSoftware/pt-v5-mainnet scripts.
contract DeployHoodBet is Script {
  function run() external {
    address prizePool = vm.envAddress("PRIZE_POOL");
    address owner = vm.envOr("SAFE_OWNER", HoodBetConfig.SAFE_OWNER);

    vm.startBroadcast();

    HoodFeeHarvester harvester = new HoodFeeHarvester(
      owner,
      prizePool,
      HoodBetConfig.MORPHO_VAULT
    );

    vm.stopBroadcast();

    console2.log("HoodFeeHarvester", address(harvester));
    console2.log("Morpho vault", HoodBetConfig.MORPHO_VAULT);
    console2.log("Owner (Safe)", owner);
    console2.log("Next: Safe sets Morpho fee recipients to harvester (timelocked)");
    console2.log("Next: harvester.setPrizeVault(prizeVaultAddress)");
  }
}
