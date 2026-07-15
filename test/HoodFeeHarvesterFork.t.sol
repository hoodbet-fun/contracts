// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {HoodFeeHarvester} from "../src/HoodFeeHarvester.sol";
import {HoodBetConfig} from "../src/HoodBetConfig.sol";

interface IPrizePoolMinimal {
  function accountedBalance() external view returns (uint256);
  function prizeToken() external view returns (address);
}

/// @notice Fork tests against live Robinhood mainnet PrizePool + Morpho vault.
contract HoodFeeHarvesterForkTest is Test {
  address internal constant PRIZE_POOL = 0x14E5004A757A85439Fc379C8AcD5b3b3CDF47344;
  address internal constant PRIZE_VAULT = 0x11da9bE66d20328c6eA16d52079890322fA90f24;
  address internal constant OLD_HARVESTER = 0x7FB9C432e78101a6bB59e681458888acaA3db532;
  address internal constant SAFE = 0x5FF989aCB81e612fb54d2BDE9C6334B4C9a8f117;

  IERC4626 morpho;
  IERC20 usdg;
  IPrizePoolMinimal pool;

  function setUp() public {
    vm.createSelectFork("https://rpc.mainnet.chain.robinhood.com");
    morpho = IERC4626(HoodBetConfig.MORPHO_VAULT);
    usdg = IERC20(HoodBetConfig.USDG);
    pool = IPrizePoolMinimal(PRIZE_POOL);
  }

  function test_fork_oldHarvester_harvest_reverts() public {
    uint256 shares = morpho.balanceOf(OLD_HARVESTER);
    if (shares == 0) return;

    vm.expectRevert();
    HoodFeeHarvester(OLD_HARVESTER).harvest();
  }

  function test_fork_fixedHarvester_harvest_contributesToPrizePool() public {
    uint256 shares = morpho.balanceOf(OLD_HARVESTER);
    if (shares == 0) return;

    HoodFeeHarvester fixedHarvester = new HoodFeeHarvester(SAFE, PRIZE_POOL, HoodBetConfig.MORPHO_VAULT);
    vm.prank(SAFE);
    fixedHarvester.setPrizeVault(PRIZE_VAULT);

    // Simulate fee shares on the fixed harvester (same amount as accrued on the broken deploy).
    deal(HoodBetConfig.MORPHO_VAULT, address(fixedHarvester), shares);

    uint256 poolBefore = pool.accountedBalance();
    uint256 expected = morpho.convertToAssets(shares);

    uint256 contributed = fixedHarvester.harvest();

    assertEq(contributed, expected);
    assertEq(pool.accountedBalance(), poolBefore + expected);
    assertEq(morpho.balanceOf(address(fixedHarvester)), 0);
    assertEq(usdg.balanceOf(address(fixedHarvester)), 0);
  }
}
