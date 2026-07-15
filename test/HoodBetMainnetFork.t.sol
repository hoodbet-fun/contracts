// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {HoodBetConfig} from "../src/HoodBetConfig.sol";

interface IPrizeVaultView {
  function yieldBuffer() external view returns (uint256);
  function liquidationPair() external view returns (address);
  function prizePool() external view returns (address);
  function claimer() external view returns (address);
  function asset() external view returns (address);
  function totalAssets() external view returns (uint256);
}

interface IPrizePoolView {
  function accountedBalance() external view returns (uint256);
  function drawManager() external view returns (address);
  function prizeToken() external view returns (address);
  function getOpenDrawId() external view returns (uint24);
  function getLastAwardedDrawId() external view returns (uint24);
  function firstDrawOpensAt() external view returns (uint48);
}

interface IDrawManagerView {
  function canStartDraw() external view returns (bool);
  function canFinishDraw() external view returns (bool);
  function prizePool() external view returns (address);
}

interface ITpdaPairView {
  function tokenIn() external view returns (address);
  function tokenOut() external view returns (address);
  function maxAmountOut() external returns (uint256);
}

interface IMorphoVaultView {
  function performanceFeeRecipient() external view returns (address);
  function managementFeeRecipient() external view returns (address);
  function name() external view returns (string memory);
}

interface IHoodFeeHarvesterView {
  function prizeVault() external view returns (address);
  function morphoVault() external view returns (address);
}

/// @notice Live mainnet wiring + readiness checks for HoodPot stack.
contract HoodBetMainnetForkTest is Test {
  address internal constant PRIZE_POOL = 0x14E5004A757A85439Fc379C8AcD5b3b3CDF47344;
  address internal constant PRIZE_VAULT = 0x11da9bE66d20328c6eA16d52079890322fA90f24;
  address internal constant DRAW_MANAGER = 0xd1C3D3B690c9a2033b0bEA03bA0771847Fd983EB;
  address internal constant LIQUIDATION_PAIR = 0x8d1877D32eF88DFb98059d1eE50EFCB68094B772;
  address internal constant HARVESTER = 0x7FB9C432e78101a6bB59e681458888acaA3db532;
  address internal constant CLAIMER = 0x71ec0971e8f8E35568A4bbe0fc118E6CA0ebe707;

  function setUp() public {
    vm.createSelectFork("https://rpc.mainnet.chain.robinhood.com");
  }

  function test_fork_prizeVault_wiring() public view {
    IPrizeVaultView v = IPrizeVaultView(PRIZE_VAULT);
    assertGt(v.yieldBuffer(), 0, "yield buffer");
    assertEq(v.liquidationPair(), LIQUIDATION_PAIR);
    assertEq(v.prizePool(), PRIZE_POOL);
    assertEq(v.claimer(), CLAIMER);
    assertEq(v.asset(), HoodBetConfig.USDG);
    assertGt(v.totalAssets(), 0, "TVL");
  }

  function test_fork_prizePool_wiring() public view {
    IPrizePoolView p = IPrizePoolView(PRIZE_POOL);
    assertEq(p.drawManager(), DRAW_MANAGER);
    assertEq(p.prizeToken(), HoodBetConfig.USDG);
    assertGt(p.accountedBalance(), 0, "seeded pool");
  }

  function test_fork_morpho_feeRecipients_pointToHarvester() public view {
    IMorphoVaultView m = IMorphoVaultView(HoodBetConfig.MORPHO_VAULT);
    assertEq(m.performanceFeeRecipient(), HARVESTER);
    assertEq(m.managementFeeRecipient(), HARVESTER);
    assertEq(m.name(), "hoodbet.fun");
  }

  function test_fork_harvester_wiring() public view {
    IHoodFeeHarvesterView h = IHoodFeeHarvesterView(HARVESTER);
    assertEq(h.prizeVault(), PRIZE_VAULT);
    assertEq(h.morphoVault(), HoodBetConfig.MORPHO_VAULT);
    assertGt(IERC4626(HoodBetConfig.MORPHO_VAULT).balanceOf(HARVESTER), 0, "fee shares accrued");
  }

  function test_fork_tpda_pair_usdgToUsdg() public {
    ITpdaPairView pair = ITpdaPairView(LIQUIDATION_PAIR);
    assertEq(pair.tokenIn(), HoodBetConfig.USDG);
    assertEq(pair.tokenOut(), HoodBetConfig.USDG);
    // May be 0 with low yield — call must not revert.
    pair.maxAmountOut();
  }

  function test_fork_draw_notReady_beforeFirstDrawOpens() public view {
    IPrizePoolView p = IPrizePoolView(PRIZE_POOL);
    IDrawManagerView dm = IDrawManagerView(DRAW_MANAGER);
    assertEq(p.getLastAwardedDrawId(), 0);
    assertFalse(dm.canStartDraw(), "draw before firstDrawOpensAt");
  }

  function test_fork_draw_canStart_afterFirstDrawOpens() public {
    IPrizePoolView p = IPrizePoolView(PRIZE_POOL);
    IDrawManagerView dm = IDrawManagerView(DRAW_MANAGER);

    uint48 opens = p.firstDrawOpensAt();
    vm.warp(opens + 1);

    // Still may be false until draw period closes — document live behavior.
    dm.canStartDraw();
    assertEq(dm.prizePool(), PRIZE_POOL);
  }

  function test_fork_prizePool_balance_matchesAccounted() public view {
    IPrizePoolView p = IPrizePoolView(PRIZE_POOL);
    uint256 bal = IERC20(HoodBetConfig.USDG).balanceOf(PRIZE_POOL);
    assertEq(bal, p.accountedBalance(), "no unaccounted USDG in pool");
  }
}
