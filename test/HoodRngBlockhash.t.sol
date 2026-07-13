// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {HoodRngBlockhash} from "../src/HoodRngBlockhash.sol";

contract HoodRngBlockhashTest is Test {
  HoodRngBlockhash rng;

  function setUp() public {
    rng = new HoodRngBlockhash(address(this));
  }

  function test_requestAndFulfill() public {
    uint32 id = rng.requestRandomness();
    vm.roll(block.number + 6);
    rng.fulfillRandomness(id);
    assertTrue(rng.isRequestComplete(id));
    assertGt(rng.randomNumber(id), 0);
  }

  function test_revert_fulfillTooEarly() public {
    uint32 id = rng.requestRandomness();
    vm.expectRevert();
    rng.fulfillRandomness(id);
  }
}
