// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../src/Web3ThunderFinanceMixer.sol";

/**
 * @title DeployWeb3ThunderFinanceMixer
 * @notice Foundry deployment script for Web3ThunderFinanceMixer prototype
 * @dev Env vars: PRIVATE_KEY, TOKEN_ADDRESS, ATOKEN_ADDRESS, POOL_ADDRESS
 */
contract DeployWeb3ThunderFinanceMixer is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        // Check deployer's "polemica" (balance/readiness)
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);
        require(deployer.balance > 0, "Insufficient balance for deployment");

        address token = vm.envAddress("TOKEN_ADDRESS");
        address aToken = vm.envAddress("ATOKEN_ADDRESS");
        address pool = vm.envAddress("POOL_ADDRESS");
        address verifier = vm.envAddress("VERIFIER_ADDRESS");

        vm.startBroadcast(pk);
        Web3ThunderFinanceMixer mixer = new Web3ThunderFinanceMixer(token, aToken, verifier);
        mixer.setPool(pool);
        mixer.setPrincipal(1000000);
        console.log("Web3ThunderFinanceMixer deployed at:", address(mixer));
        console.log("Admin:", deployer);
        vm.stopBroadcast();

        // Verification instructions
        console.log("To verify on CeloScan:");
        string memory cmd = string.concat(
            "forge verify-contract --chain-id 42220 --watch --constructor-args $(cast abi-encode \"constructor(address,address,address)\" ",
            vm.toString(token), ",", 
            vm.toString(aToken), ",", 
            vm.toString(verifier),
            ") ",
            vm.toString(address(mixer)),
            " src/Web3ThunderFinanceMixer.sol:Web3ThunderFinanceMixer"
        );
        console.log(cmd);
    }
}
