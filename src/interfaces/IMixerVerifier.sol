// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IMixerVerifier {
  // Expected public inputs order: [root, nullifierHash, amount]
  function verifyProof(uint[2] memory a, uint[2][2] memory b, uint[2] memory c, uint[3] memory input) external view returns (bool);
}