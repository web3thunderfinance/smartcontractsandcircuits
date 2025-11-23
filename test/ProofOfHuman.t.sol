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

    function testPerformCustomVerificationHook() public {
        // Prepare test data
        uint256[4] memory forbiddenCountriesListPacked;
        string[] memory name = new string[](1);
        name[0] = "John Doe";
        bool[3] memory ofac;
        
        ISelfVerificationRoot.GenericDiscloseOutputV2 memory output = ISelfVerificationRoot.GenericDiscloseOutputV2({
            attestationId: bytes32("test-attestation"),
            userIdentifier: 12345,
            nullifier: 67890,
            forbiddenCountriesListPacked: forbiddenCountriesListPacked,
            issuingState: "BR",
            name: name,
            idNumber: "ID-123",
            nationality: "BRA",
            dateOfBirth: "20000101",
            gender: "M",
            expiryDate: "20300101",
            olderThan: 18,
            ofac: ofac
        });

        bytes memory userData = "test-user-data";

        // Expect the event
        // Note: Events defined in the contract under test need to be emitted with the contract type prefix if accessed externally, 
        // but here we are inside the test contract. 
        // However, vm.expectEmit checks the next emitted event.
        // We need to emit the event exactly as the contract does.
        // Since the event is defined in ProofOfHuman, we can't emit it directly from the Test contract easily 
        // unless we redefine it or use the low-level log.
        // Actually, we can just check if the event was emitted by checking the logs or using expectEmit with the selector.
        
        // Let's try to define the event in the interface or just use the selector.
        // Or simpler: The event is public in the contract? Events are not really public/private in that sense, but they are part of the ABI.
        
        // To use vm.expectEmit, we usually emit the expected event in the test.
        // But we can't emit ProofOfHuman.VerificationCompleted because we are in ProofOfHumanTest.
        // We can define the event in the Test contract to match.
        
        vm.expectEmit(true, true, true, true);
        emit VerificationCompleted(output, userData);

        // Call the function
        proofOfHuman.performCustomVerificationHook(output, userData);
    }

    // Redefine event to match ProofOfHuman's event for testing purposes
    event VerificationCompleted(
        ISelfVerificationRoot.GenericDiscloseOutputV2 output,
        bytes userData
    );
}
