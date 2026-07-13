// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {HoodPointsRegistry} from "../src/HoodPointsRegistry.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract HoodPointsRegistryTest is Test {
  MockERC20 hood;
  HoodPointsRegistry registry;

  address user = makeAddr("user");

  function setUp() public {
    hood = new MockERC20("HOOD", "HOOD", 18);
    uint256[4] memory thresholds = [uint256(0), 10_000e18, 100_000e18, 1_000_000e18];
    registry = new HoodPointsRegistry(address(this), address(hood), thresholds);
  }

  function test_tierScout() public view {
    assertEq(registry.getTier(user), 0);
    assertEq(registry.getReferralMultiplierBps(user), 10_000);
  }

  function test_tierHood() public {
    hood.mint(user, 10_000e18);
    assertEq(registry.getTier(user), 1);
    assertEq(registry.getReferralMultiplierBps(user), 12_500);
  }

  function test_tierLegend() public {
    hood.mint(user, 100_000e18);
    assertEq(registry.getTier(user), 2);
  }

  function test_tierOG() public {
    hood.mint(user, 1_000_000e18);
    assertEq(registry.getTier(user), 3);
    assertEq(registry.getReferralMultiplierBps(user), 20_000);
  }
}
