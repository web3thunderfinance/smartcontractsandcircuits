// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Script.sol";
import "../src/Web3ThunderFinanceProtocol.sol";

/**
 * @title DeployWeb3ThunderFinanceProtocol
 * @notice Deployment script for the Web3 Thunder Finance Protocol
 * @dev Run with: forge script script/DeployWeb3ThunderFinanceProtocol.s.sol:DeployWeb3ThunderFinanceProtocol --rpc-url <your_rpc_url> --broadcast --verify
 */
contract DeployWeb3ThunderFinanceProtocol is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Web3 Thunder Finance Protocol
        Web3ThunderFinanceProtocol protocol = new Web3ThunderFinanceProtocol();
        
        console.log("Web3ThunderFinanceProtocol deployed at:", address(protocol));
        console.log("Admin address:", vm.addr(deployerPrivateKey));

        vm.stopBroadcast();
    }
}
