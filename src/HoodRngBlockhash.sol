// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IRng} from "./interfaces/IRng.sol";

/// @title HoodRngBlockhash
/// @notice MVP RNG for Robinhood Chain — uses future blockhash after REQUEST_DELAY blocks.
/// @dev Upgrade to Witnet or Chainlink VRF for production. See docs/RNG.md.
contract HoodRngBlockhash is IRng, Ownable {
  uint256 public constant REQUEST_DELAY = 5;

  struct Request {
    uint256 requestedAtBlock;
    uint256 fulfilledAtBlock;
    uint256 randomNumber;
    bool failed;
  }

  mapping(uint32 => Request) public requests;
  uint32 public nextRequestId = 1;

  event RandomnessRequested(uint32 indexed requestId, uint256 atBlock);
  event RandomnessFulfilled(uint32 indexed requestId, uint256 randomNumber);

  constructor(address owner_) Ownable(owner_) {}

  /// @notice Start a new RNG request (called by draw bot / DrawManager flow).
  function requestRandomness() external returns (uint32 requestId) {
    requestId = nextRequestId++;
    requests[requestId] = Request({requestedAtBlock: block.number, fulfilledAtBlock: 0, randomNumber: 0, failed: false});
    emit RandomnessRequested(requestId, block.number);
  }

  /// @notice Fulfill request once REQUEST_DELAY blocks have passed.
  function fulfillRandomness(uint32 requestId) external {
    Request storage req = requests[requestId];
    require(req.requestedAtBlock != 0, "Unknown request");
    require(req.fulfilledAtBlock == 0, "Already fulfilled");
    require(block.number > req.requestedAtBlock + REQUEST_DELAY, "Too early");

    bytes32 bh = blockhash(req.requestedAtBlock + REQUEST_DELAY);
    if (bh == bytes32(0)) {
      req.failed = true;
      req.fulfilledAtBlock = block.number;
      return;
    }

    req.randomNumber = uint256(keccak256(abi.encodePacked(bh, requestId, block.prevrandao, block.timestamp)));
    req.fulfilledAtBlock = block.number;
    emit RandomnessFulfilled(requestId, req.randomNumber);
  }

  function requestedAtBlock(uint32 rngRequestId) external returns (uint256) {
    return requests[rngRequestId].requestedAtBlock;
  }

  function isRequestComplete(uint32 rngRequestId) external view returns (bool) {
    Request storage req = requests[rngRequestId];
    return req.fulfilledAtBlock != 0 && !req.failed && req.randomNumber != 0;
  }

  function isRequestFailed(uint32 rngRequestId) external view returns (bool) {
    return requests[rngRequestId].failed;
  }

  function randomNumber(uint32 rngRequestId) external returns (uint256) {
    Request storage req = requests[rngRequestId];
    require(req.fulfilledAtBlock != 0 && !req.failed, "Not ready");
    return req.randomNumber;
  }
}
