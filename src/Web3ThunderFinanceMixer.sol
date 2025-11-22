// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./interfaces/IAavePool.sol";

/**
 * @title Web3ThunderFinanceMixer
 * @author Web3 Thunder Finance Team
 * @notice Privacy-oriented yield mixer: pools deposits, supplies them to Aave, accrues yield, enables private(ish) withdrawal via commitment/nullifier.
 * @dev Prototype: NO Merkle tree, NO zk-proof verification. Do not rely on real anonymity.
 * @custom:security-contact security@web3thunderfinance.io
 */
contract Web3ThunderFinanceMixer is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // --- Roles ---
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // --- External Protocol References ---
    IAavePool public pool;            // Aave pool
    IERC20 public immutable token;    // Underlying asset (e.g., USDC)
    IERC20 public immutable aToken;   // Corresponding aToken accruing yield

    // --- Accounting ---
    uint256 public totalPrincipal;    // Sum of all active deposit principals

    // --- Deposit Model ---
    struct DepositInfo {
        uint256 amount;       // Principal supplied
        uint64  timestamp;    // Block timestamp of deposit
        bool    withdrawn;    // Withdrawal status
    }

    // commitment => deposit
    mapping(bytes32 => DepositInfo) public deposits;

    // nullifier => spent status
    mapping(bytes32 => bool) public nullifiers;

    // --- Events ---
    /**
     * @notice Emitted when the Aave pool reference is updated.
     * @param oldPool Previously configured pool address.
     * @param newPool Newly configured pool address.
     */
    event PoolUpdated(address indexed oldPool, address indexed newPool);

    /**
     * @notice Emitted when a deposit commitment is recorded.
     * @param commitment Commitment hash provided by depositor.
     * @param amount Principal amount supplied.
     * @param timestamp Block timestamp of the deposit.
     */
    event DepositCommitted(bytes32 indexed commitment, uint256 amount, uint64 timestamp);

    /**
     * @notice Emitted upon successful withdrawal of principal + yield.
     * @param commitment Commitment associated with the original deposit.
     * @param nullifier Nullifier marking the withdrawal and preventing reuse.
     * @param recipient Address receiving the withdrawn underlying.
     * @param principal Original principal returned.
     * @param yieldAmount Pro-rata yield portion distributed.
     */
    event Withdrawn(bytes32 indexed commitment, bytes32 indexed nullifier, address indexed recipient, uint256 principal, uint256 yieldAmount);

    /**
     * @notice Emitted on emergency administrative withdrawal.
     * @param token Underlying token address withdrawn.
     * @param amount Amount of underlying moved out.
     * @param to Recipient address receiving funds.
     */
    event EmergencyWithdraw(address indexed token, uint256 amount, address indexed to);

    // --- Errors ---
    error CommitmentUsed();
    error InvalidAmount();
    error NotFound();
    error AlreadyWithdrawn();
    error NullifierUsed();
    error UnauthorizedCaller();
    error ZeroAddress();
    error PoolNotSet();

    /**
     * @notice Construct mixer with immutable token & aToken addresses.
     * @param _token Underlying ERC20 asset address
     * @param _aToken Aave aToken corresponding to the underlying
     * @dev Pool can be set later via admin if unknown at deploy time.
     */
    constructor(address _token, address _aToken) {
        if (_token == address(0) || _aToken == address(0)) revert ZeroAddress();
        token = IERC20(_token);
        aToken = IERC20(_aToken);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Sets or updates the Aave pool address used for supply/withdraw.
     * @dev Changing the pool mid-flight may affect yield assumptions; intended only for migrations.
     * @param _pool New pool address.
     */
    function setPool(address _pool) external onlyRole(ADMIN_ROLE) {
        if (_pool == address(0)) revert ZeroAddress();
        address old = address(pool);
        pool = IAavePool(_pool);
        emit PoolUpdated(old, _pool);
    }

    /**
     * @notice Pause protocol operations.
     */
    function pause() external onlyRole(ADMIN_ROLE) { _pause(); }

    /**
     * @notice Unpause protocol operations.
     */
    function unpause() external onlyRole(ADMIN_ROLE) { _unpause(); }

    /**
     * @notice Commit a deposit with a precomputed commitment.
     * @dev Sequence: transfer underlying -> approve -> supply to pool -> record principal. Assumes non fee-on-transfer token.
     * @param commitment Off-chain keccak256(secret, amount) style hash.
     * @param amount Amount of underlying to deposit & supply.
     */
    function deposit(bytes32 commitment, uint256 amount) external nonReentrant whenNotPaused {
        if (amount == 0) revert InvalidAmount();
        if (deposits[commitment].amount != 0) revert CommitmentUsed();
        if (address(pool) == address(0)) revert PoolNotSet();

        token.safeTransferFrom(msg.sender, address(this), amount);
        token.safeApprove(address(pool), amount);
        pool.supply(address(token), amount, address(this), 0);

        deposits[commitment] = DepositInfo({
            amount: amount,
            timestamp: uint64(block.timestamp),
            withdrawn: false
        });
        totalPrincipal += amount;

        emit DepositCommitted(commitment, amount, uint64(block.timestamp));
    }

    /**
     * @notice Withdraw principal plus proportional accrued yield using a nullifier.
     * @dev Prototype (no zk-proof). Applies checks-effects-interactions order.
     * @param commitment Commitment corresponding to original deposit.
     * @param nullifier Unique nullifier derived from secret; prevents double-withdraw.
     * @param recipient Address receiving withdrawn funds.
     */
    function withdraw(bytes32 commitment, bytes32 nullifier, address recipient) external nonReentrant whenNotPaused {
        if (recipient == address(0)) revert ZeroAddress();
        DepositInfo storage info = deposits[commitment];
        if (info.amount == 0) revert NotFound();
        // Reorder checks so nullifier reuse surfaces the expected NullifierUsed error
        if (nullifiers[nullifier]) revert NullifierUsed();
        if (info.withdrawn) revert AlreadyWithdrawn();

        // Compute distribution BEFORE mutating totalPrincipal to ensure fair pro-rata calculation
        (uint256 principal, uint256 yieldAmount) = _computeShare(info.amount);
        uint256 totalAmount = principal + yieldAmount;

        // Effects
        info.withdrawn = true;
        nullifiers[nullifier] = true;
        totalPrincipal -= principal; // subtract original principal after share calculation

        // Interaction
        pool.withdraw(address(token), totalAmount, recipient);

        emit Withdrawn(commitment, nullifier, recipient, principal, yieldAmount);
    }

    /**
     * @notice Preview yield share for a given principal amount.
     * @dev Uses aToken balance minus totalPrincipal to compute aggregate yield then allocates pro-rata.
     * @param principal Deposit principal to preview.
     * @return yieldAmount Current proportional yield.
     */
    function previewYield(uint256 principal) external view returns (uint256 yieldAmount) {
        (, uint256 y) = _computeShare(principal);
        return y;
    }

    /**
     * @dev Computes principal echo plus proportional yield for a given principal.
     * @param principal Principal amount supplied.
     * @return principalEcho Echo of principal.
     * @return yieldShare Pro-rata yield share; zero if no net yield.
     */
    function _computeShare(uint256 principal) internal view returns (uint256 principalEcho, uint256 yieldShare) {
        principalEcho = principal;
        uint256 aBal = aToken.balanceOf(address(this));
        if (aBal <= totalPrincipal || totalPrincipal == 0) {
            return (principalEcho, 0);
        }
        uint256 totalYield = aBal - totalPrincipal;
        yieldShare = (totalYield * principal) / totalPrincipal;
    }

    /**
     * @notice Emergency withdraw underlying token balance (admin only).
     * @dev Breaks accounting invariants; use only in recovery scenarios.
     * @param amount Amount to withdraw (0 = full aToken equivalent).
     * @param to Recipient address.
     */
    function emergencyWithdraw(uint256 amount, address to) external onlyRole(ADMIN_ROLE) {
        if (to == address(0)) revert ZeroAddress();
        if (address(pool) == address(0)) revert PoolNotSet();
        uint256 toWithdraw = amount == 0 ? aToken.balanceOf(address(this)) : amount;
        pool.withdraw(address(token), toWithdraw, to);
        emit EmergencyWithdraw(address(token), toWithdraw, to);
    }

    /**
     * @notice Checks if a commitment has an associated record.
     * @param commitment Commitment hash supplied during deposit.
     * @return exists True if a deposit record exists.
     */
    function hasCommitment(bytes32 commitment) external view returns (bool exists) {
        return deposits[commitment].amount != 0;
    }

    /**
     * @notice Checks if a nullifier has already been consumed.
     * @param nullifier Nullifier hash derived from secret.
     * @return used True if marked used.
     */
    function isNullifierUsed(bytes32 nullifier) external view returns (bool used) {
        return nullifiers[nullifier];
    }
}
