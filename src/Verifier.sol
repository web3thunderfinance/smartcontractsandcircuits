// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./interfaces/IMixerVerifier.sol";

contract Verifier is IMixerVerifier {
    function verifyProof(
        uint[2] memory /* a */,
        uint[2][2] memory /* b */,
        uint[2] memory /* c */,
        uint[3] memory /* input */
    ) external pure override returns (bool) {
        // TODO: Replace with actual verification logic (e.g. from snarkjs)
        return true;
    }
}
