// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {HoodFeeHarvester} from "../src/HoodFeeHarvester.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockERC4626} from "./mocks/MockERC4626.sol";
import {MockPrizePool} from "./mocks/MockPrizePool.sol";

contract HoodFeeHarvesterTest is Test {
  MockERC20 usdg;
  MockERC4626 morphoVault;
  MockPrizePool prizePool;
  HoodFeeHarvester harvester;

  address safe = makeAddr("safe");
  address prizeVault = makeAddr("prizeVault");

  function setUp() public {
    usdg = new MockERC20("USDG", "USDG", 6);
    morphoVault = new MockERC4626(usdg, "hoodbet.fun", "hbUSDG");
    prizePool = new MockPrizePool(address(usdg));

    harvester = new HoodFeeHarvester(safe, address(prizePool), address(morphoVault));

    vm.prank(safe);
    harvester.setPrizeVault(prizeVault);

    // Seed vault with assets and mint fee shares to harvester (simulates Morpho fee accrual)
    usdg.mint(address(this), 1_000_000e6);
    usdg.approve(address(morphoVault), type(uint256).max);
    morphoVault.deposit(1_000_000e6, address(this));

    morphoVault.mintFeeShares(address(harvester), 50_000e6);
  }

  function test_harvest_contributesToPrizePool() public {
    uint256 poolBefore = usdg.balanceOf(address(prizePool));
    uint256 expected = morphoVault.convertToAssets(morphoVault.balanceOf(address(harvester)));

    uint256 contributed = harvester.harvest();

    assertEq(contributed, expected);
    assertEq(usdg.balanceOf(address(prizePool)), poolBefore + expected);
    assertEq(prizePool.contributions(prizeVault), expected);
    assertEq(morphoVault.balanceOf(address(harvester)), 0);
  }

  function test_revert_harvest_withoutPrizeVault() public {
    HoodFeeHarvester fresh = new HoodFeeHarvester(safe, address(prizePool), address(morphoVault));

    morphoVault.mintFeeShares(address(fresh), 1e6);

    vm.expectRevert(HoodFeeHarvester.PrizeVaultNotSet.selector);
    fresh.harvest();
  }

  function test_revert_harvest_zeroShares() public {
    HoodFeeHarvester emptyHarvester = new HoodFeeHarvester(safe, address(prizePool), address(morphoVault));
    vm.prank(safe);
    emptyHarvester.setPrizeVault(prizeVault);

    vm.expectRevert(HoodFeeHarvester.ZeroShares.selector);
    emptyHarvester.harvest();
  }

  function test_onlyOwner_canSetPrizeVault() public {
    vm.prank(makeAddr("attacker"));
    vm.expectRevert();
    harvester.setPrizeVault(makeAddr("other"));
  }

  function test_revert_assetMismatch() public {
    MockERC20 other = new MockERC20("OTHER", "OTH", 18);
    MockPrizePool otherPool = new MockPrizePool(address(other));

    vm.expectRevert(HoodFeeHarvester.AssetMismatch.selector);
    new HoodFeeHarvester(safe, address(otherPool), address(morphoVault));
  }
}
