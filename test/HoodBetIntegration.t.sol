// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {HoodFeeHarvester} from "../src/HoodFeeHarvester.sol";
import {HoodPointsRegistry} from "../src/HoodPointsRegistry.sol";
import {HoodRngBlockhash} from "../src/HoodRngBlockhash.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockERC4626} from "./mocks/MockERC4626.sol";
import {MockPrizePool} from "./mocks/MockPrizePool.sol";
import {HoodBetConfig} from "../src/HoodBetConfig.sol";

/// @notice Integration flow: fee harvest + RNG + points tier (fork-mainnet scaffold).
contract HoodBetIntegrationTest is Test {
  uint256 robinhoodFork;

  function setUp() public {
    robinhoodFork = vm.createFork("https://rpc.mainnet.chain.robinhood.com");
  }

  function test_fork_morphoVault_config() public {
    vm.selectFork(robinhoodFork);
    (bool ok, bytes memory data) = HoodBetConfig.MORPHO_VAULT.staticcall(abi.encodeWithSignature("name()"));
    assertTrue(ok);
    string memory name = abi.decode(data, (string));
    assertEq(name, "hoodbet.fun");
  }

  function test_e2e_harvest_rng_points() public {
    MockERC20 usdg = new MockERC20("USDG", "USDG", 6);
    MockERC20 hood = new MockERC20("HOOD", "HOOD", 18);
    MockERC4626 morpho = new MockERC4626(usdg, "hoodbet.fun", "hbUSDG");
    MockPrizePool pool = new MockPrizePool(address(usdg));

    address safe = makeAddr("safe");
    address prizeVault = makeAddr("prizeVault");
    address user = makeAddr("user");

    HoodFeeHarvester harvester = new HoodFeeHarvester(safe, address(pool), address(morpho));
    vm.prank(safe);
    harvester.setPrizeVault(prizeVault);

    uint256[4] memory thresholds = [uint256(0), 10_000e18, 100_000e18, 1_000_000e18];
    HoodPointsRegistry points = new HoodPointsRegistry(safe, address(hood), thresholds);

    HoodRngBlockhash rng = new HoodRngBlockhash(safe);

    usdg.mint(address(this), 1_000_000e6);
    usdg.approve(address(morpho), type(uint256).max);
    morpho.deposit(1_000_000e6, address(this));
    morpho.mintFeeShares(address(harvester), 50_000e6);
    harvester.harvest();

    hood.mint(user, 50_000e18);
    assertEq(points.getTier(user), 1);

    uint32 rngId = rng.requestRandomness();
    vm.roll(block.number + 6);
    rng.fulfillRandomness(rngId);
    assertTrue(rng.isRequestComplete(rngId));

    assertEq(pool.contributions(prizeVault), morpho.convertToAssets(50_000e6));
  }
}
