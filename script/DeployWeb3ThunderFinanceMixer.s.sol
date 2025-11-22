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
        address token = vm.envAddress("TOKEN_ADDRESS");
        address aToken = vm.envAddress("ATOKEN_ADDRESS");
        address pool = vm.envAddress("POOL_ADDRESS");

        vm.startBroadcast(pk);
        Web3ThunderFinanceMixer mixer = new Web3ThunderFinanceMixer(token, aToken);
        mixer.setPool(pool);
        console.log("Web3ThunderFinanceMixer deployed at:", address(mixer));
        console.log("Admin:", vm.addr(pk));
        vm.stopBroadcast();
    }
}
