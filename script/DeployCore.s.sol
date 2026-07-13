// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {HoodFeeHarvester} from "../src/HoodFeeHarvester.sol";
import {HoodRngBlockhash} from "../src/HoodRngBlockhash.sol";
import {HoodPointsRegistry} from "../src/HoodPointsRegistry.sol";
import {HoodBetConfig} from "../src/HoodBetConfig.sol";

/// @title DeployCore
/// @notice Deploy HoodBet custom contracts. PT V5 core via pt-deploy/ (GenerationSoftware/pt-v5-mainnet).
contract DeployCore is Script {
  function run() external {
    address owner = vm.envOr("SAFE_OWNER", HoodBetConfig.SAFE_OWNER);
    address prizePool = vm.envOr("PRIZE_POOL", address(0));
    address hoodToken = vm.envOr("HOOD_TOKEN", address(0));

    vm.startBroadcast();

    HoodRngBlockhash rng = new HoodRngBlockhash(owner);
    console2.log("HoodRngBlockhash", address(rng));

    if (prizePool != address(0)) {
      HoodFeeHarvester harvester = new HoodFeeHarvester(owner, prizePool, HoodBetConfig.MORPHO_VAULT);
      console2.log("HoodFeeHarvester", address(harvester));
    }

    if (hoodToken != address(0)) {
      uint256[4] memory thresholds = [uint256(0), 10_000e18, 100_000e18, 1_000_000e18];
      HoodPointsRegistry points = new HoodPointsRegistry(owner, hoodToken, thresholds);
      console2.log("HoodPointsRegistry", address(points));
    }

    vm.stopBroadcast();

    console2.log("Next: deploy PT core from pt-deploy/README.md");
    console2.log("Next: Safe wires Morpho fee recipients to HoodFeeHarvester");
  }
}
