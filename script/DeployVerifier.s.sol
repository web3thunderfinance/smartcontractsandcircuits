// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "../src/Verifier.sol";

contract DeployVerifier is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);
        Verifier verifier = new Verifier();
        console.log("Verifier deployed at:", address(verifier));
        vm.stopBroadcast();
    }
}
