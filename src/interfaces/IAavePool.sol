// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/**
 * @title IAavePool
 * @notice Minimal interface for Aave V3 Pool integration (supply & withdraw)
 * @dev Extend as needed for flash loans, interest rate modes, etc.
 */
interface IAavePool {
    /**
     * @notice Supplies `amount` of `asset` into Aave on behalf of `onBehalfOf`
     * @param asset ERC20 token address
     * @param amount Amount to supply
     * @param onBehalfOf Beneficiary whose aToken balance increases
     * @param referralCode Deprecated in V3 (pass 0)
     */
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /**
     * @notice Withdraws `amount` of `asset` to `to` address
     * @param asset ERC20 token address
     * @param amount Amount to withdraw (`type(uint256).max` for full balance)
     * @param to Recipient of underlying asset
     * @return withdrawn Actual amount withdrawn
     */
    function withdraw(address asset, uint256 amount, address to) external returns (uint256 withdrawn);
}
