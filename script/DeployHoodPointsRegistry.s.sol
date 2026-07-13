// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {HoodPointsRegistry} from "../src/HoodPointsRegistry.sol";
import {HoodBetConfig} from "../src/HoodBetConfig.sol";

/// @notice Deploy HoodPointsRegistry only — reads $HOOD balance for tier badges.
contract DeployHoodPointsRegistry is Script {
  function run() external {
    address owner = vm.envOr("SAFE_OWNER", HoodBetConfig.SAFE_OWNER);
    address hoodToken = vm.envAddress("HOOD_TOKEN");

    uint256[4] memory thresholds = [uint256(0), 10_000e18, 100_000e18, 1_000_000e18];

    vm.startBroadcast();
    HoodPointsRegistry registry = new HoodPointsRegistry(owner, hoodToken, thresholds);
    vm.stopBroadcast();

    console2.log("HoodPointsRegistry", address(registry));
    console2.log("hoodToken", hoodToken);
    console2.log("owner", owner);
  }
}
