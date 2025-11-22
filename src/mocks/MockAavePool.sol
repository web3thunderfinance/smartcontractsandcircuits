// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MockAavePool
 * @notice Simple pool mock: on supply, transfers underlying into pool and mints 1:1 aTokens; on withdraw burns aTokens and returns underlying.
 */
interface IMintableAToken {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

contract MockAavePool {
    using SafeERC20 for IERC20;

    IERC20 public immutable underlying;
    IMintableAToken public immutable aToken;

    constructor(address _underlying, address _aToken) {
        underlying = IERC20(_underlying);
        aToken = IMintableAToken(_aToken);
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        require(asset == address(underlying), "asset mismatch");
        underlying.safeTransferFrom(msg.sender, address(this), amount);
        aToken.mint(onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256 withdrawn) {
        require(asset == address(underlying), "asset mismatch");
        uint256 bal = aToken.balanceOf(msg.sender);
        uint256 toBurn = amount;
        if (amount == type(uint256).max) {
            toBurn = bal;
        } else {
            require(bal >= amount, "insufficient aToken");
        }
        aToken.burn(msg.sender, toBurn);
        underlying.safeTransfer(to, toBurn);
        return toBurn;
    }
}
