// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockAToken is ERC20 {
    address public pool;

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        pool = msg.sender; // deployer becomes pool initially; can be reset
    }

    modifier onlyPool() { require(msg.sender == pool, "only pool"); _; }

    function setPool(address p) external onlyPool { pool = p; }

    function mint(address to, uint256 amount) external onlyPool { _mint(to, amount); }
    function burn(address from, uint256 amount) external onlyPool { _burn(from, amount); }
}
