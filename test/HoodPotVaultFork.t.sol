// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {HoodBetConfig} from "../src/HoodBetConfig.sol";
import {
  IPrizeVaultFactory,
  IPrizeVaultMinimal,
  ITpdaLiquidationPairFactory
} from "../src/interfaces/IPrizeVaultFactory.sol";

/// @notice Fork test: PrizeVault deploy with yield buffer opens deposits.
contract HoodPotVaultForkTest is Test {
  address internal constant PRIZE_POOL = 0x14E5004A757A85439Fc379C8AcD5b3b3CDF47344;
  address internal constant CLAIMER = 0x71ec0971e8f8E35568A4bbe0fc118E6CA0ebe707;
  address internal constant FACTORY = 0xa81B8281586115a228763A584734325BEb71E5c2;
  address internal constant LP_FACTORY = 0x00049FcE2De06310805693b00b63755cA6B22Fe7;
  address internal constant DEPLOYER = 0x8Ac130E606545aD94E26fCF09CcDd950A981A704;

  uint256 internal constant YIELD_BUFFER = 500_000;

  function test_fork_deployVault_withYieldBuffer() public {
    vm.createSelectFork("https://rpc.mainnet.chain.robinhood.com");

    IERC20 usdg = IERC20(HoodBetConfig.USDG);
    uint256 bal = usdg.balanceOf(DEPLOYER);
    vm.assume(bal >= YIELD_BUFFER);

    vm.startPrank(DEPLOYER);
    usdg.approve(FACTORY, YIELD_BUFFER);

    address vault = IPrizeVaultFactory(FACTORY).deployVault(
      "HoodPot Test",
      "hpT",
      IERC4626(HoodBetConfig.MORPHO_VAULT),
      PRIZE_POOL,
      CLAIMER,
      address(0),
      0,
      YIELD_BUFFER,
      DEPLOYER
    );

    IPrizeVaultMinimal v = IPrizeVaultMinimal(vault);
    assertEq(v.yieldBuffer(), YIELD_BUFFER);

    address pair = ITpdaLiquidationPairFactory(LP_FACTORY).createPair(
      vault,
      HoodBetConfig.USDG,
      HoodBetConfig.USDG,
      86_400,
      1_000_000,
      0.1e18
    );
    v.setLiquidationPair(pair);
    vm.stopPrank();

    assertTrue(IPrizeVaultFactory(FACTORY).deployedVaults(vault));
  }
}
