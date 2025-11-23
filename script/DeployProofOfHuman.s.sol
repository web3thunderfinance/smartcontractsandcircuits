// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../src/proofofhuman.sol";
import {SelfUtils} from "@selfxyz/contracts/contracts/libraries/SelfUtils.sol";

contract DeployProofOfHuman is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Default to Celo Mainnet address if not provided
        address hubAddress = vm.envOr("IDENTITY_VERIFICATION_HUB_ADDRESS", 0xe57F4773bd9c9d8b6Cd70431117d353298B9f5BF);
        string memory scopeSeed = vm.envOr("SCOPE_SEED", string("web3thunderfinance"));
        
        // Config
        uint256 olderThan = 18;
        string[] memory forbiddenCountries = new string[](0);
        bool ofacEnabled = true;

        SelfUtils.UnformattedVerificationConfigV2 memory config = SelfUtils.UnformattedVerificationConfigV2({
            olderThan: olderThan,
            forbiddenCountries: forbiddenCountries,
            ofacEnabled: ofacEnabled
        });

        vm.startBroadcast(deployerPrivateKey);

        ProofOfHuman proofOfHuman = new ProofOfHuman(
            hubAddress,
            scopeSeed,
            config
        );

        console.log("ProofOfHuman deployed at:", address(proofOfHuman));

        vm.stopBroadcast();
    }
}
