// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/proofofhuman.sol";
import {SelfUtils} from "@selfxyz/contracts/contracts/libraries/SelfUtils.sol";
import {SelfStructs} from "@selfxyz/contracts/contracts/libraries/SelfStructs.sol";
import {ISelfVerificationRoot} from "@selfxyz/contracts/contracts/interfaces/ISelfVerificationRoot.sol";

contract MockIdentityVerificationHubV2 {
    bytes32 public lastConfigId;
    
    function setVerificationConfigV2(
        SelfStructs.VerificationConfigV2 memory /* config */
    ) external returns (bytes32) {
        lastConfigId = keccak256(abi.encodePacked(block.timestamp)); // Mock ID
        return lastConfigId;
    }
}

contract ProofOfHumanTest is Test {
    ProofOfHuman public proofOfHuman;
    MockIdentityVerificationHubV2 public mockHub;
    
    function setUp() public {
        mockHub = new MockIdentityVerificationHubV2();
        
        string[] memory forbiddenCountries = new string[](1);
        forbiddenCountries[0] = "USA";
        
        SelfUtils.UnformattedVerificationConfigV2 memory config = SelfUtils.UnformattedVerificationConfigV2({
            olderThan: 18,
            forbiddenCountries: forbiddenCountries,
            ofacEnabled: true
        });

        proofOfHuman = new ProofOfHuman(
            address(mockHub),
            "test-scope",
            config
        );
    }

    function testDeployment() public {
        assertEq(proofOfHuman.verificationConfigId(), mockHub.lastConfigId());
    }

    function testGetConfigId() public {
        bytes32 configId = proofOfHuman.getConfigId(bytes32(0), bytes32(0), "");
        assertEq(configId, mockHub.lastConfigId());
    }
}
