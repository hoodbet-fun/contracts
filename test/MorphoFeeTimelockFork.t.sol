// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

/// @dev Morpho Vault V2 fee recipients require submit() before direct calls (timelock=0 on this vault).
contract MorphoFeeTimelockForkTest is Test {
    address constant MORPHO = 0xDF06045aBAE69d6e73a7F0197FED917032d22194;
    address constant HARVESTER = 0x7FB9C432e78101a6bB59e681458888acaA3db532;
    address constant SAFE = 0x5FF989aCB81e612fb54d2BDE9C6334B4C9a8f117;

    function setUp() public {
        vm.createSelectFork("https://rpc.mainnet.chain.robinhood.com");
    }

    function test_submitThenExecuteFeeRecipients_sameBlock() public {
        bytes memory perf = abi.encodeWithSelector(bytes4(0x6a5f1aa2), HARVESTER);
        bytes memory mgmt = abi.encodeWithSelector(bytes4(0x9faae464), HARVESTER);

        vm.startPrank(SAFE);
        (bool ok1,) = MORPHO.call(abi.encodeWithSignature("submit(bytes)", perf));
        assertTrue(ok1, "submit perf");
        (bool ok2,) = MORPHO.call(perf);
        assertTrue(ok2, "exec perf");
        (bool ok3,) = MORPHO.call(abi.encodeWithSignature("submit(bytes)", mgmt));
        assertTrue(ok3, "submit mgmt");
        (bool ok4,) = MORPHO.call(mgmt);
        assertTrue(ok4, "exec mgmt");
        vm.stopPrank();
    }
}
