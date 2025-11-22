// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title Web3ThunderFinanceProtocol
 * @author Web3 Thunder Finance Team
 * @notice Main smart contract for the Web3 Thunder Finance Protocol
 * @dev This contract manages validators, borrowers, and investors, and handles ERC20 stablecoin transfers
 * @custom:security-contact security@web3thunderfinance.io
 */
contract Web3ThunderFinanceProtocol is AccessControl, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    /// @notice Role identifier for protocol administrators
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    /// @notice Role identifier for validators who can verify transactions
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    
    /// @notice Role identifier for borrowers who can request loans
    bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");
    
    /// @notice Role identifier for investors who provide liquidity
    bytes32 public constant INVESTOR_ROLE = keccak256("INVESTOR_ROLE");

    /// @notice Minimum stake required for validators in wei (native token)
    uint256 public validatorStakeMinimum;

    /// @notice Enum representing the status of a participant
    enum ParticipantStatus {
        Active,
        Blocked,
        Removed
    }

    /// @notice Struct containing participant information
    struct Participant {
        address account;
        ParticipantStatus status;
        uint256 registeredAt;
        uint256 updatedAt;
        bytes32 role;
    }

    /// @notice Mapping of address to Participant details
    mapping(address => Participant) public participants;

    /// @notice Mapping of validator address to their staked amount
    mapping(address => uint256) public validatorStakes;

    /// @notice Array of all validator addresses
    address[] public validators;

    /// @notice Array of all borrower addresses
    address[] public borrowers;

    /// @notice Array of all investor addresses
    address[] public investors;

    /// @notice Mapping of supported stablecoin addresses
    mapping(address => bool) public supportedStablecoins;

    /// @notice Array of all supported stablecoin addresses
    address[] public stablecoinsList;

    /// @notice Total deposits per stablecoin
    mapping(address => uint256) public totalDeposits;

    /// @notice Individual balances per user per stablecoin
    mapping(address => mapping(address => uint256)) public balances;

    /// @notice Emitted when a validator is added
    event ValidatorAdded(address indexed validator, uint256 timestamp);

    /// @notice Emitted when a validator is blocked
    event ValidatorBlocked(address indexed validator, uint256 timestamp);

    /// @notice Emitted when a validator is removed
    event ValidatorRemoved(address indexed validator, uint256 timestamp);

    /// @notice Emitted when validator stake minimum is updated
    event ValidatorStakeMinimumUpdated(uint256 oldMinimum, uint256 newMinimum, uint256 timestamp);

    /// @notice Emitted when a validator stakes tokens
    event ValidatorStaked(address indexed validator, uint256 amount, uint256 timestamp);

    /// @notice Emitted when a borrower is added
    event BorrowerAdded(address indexed borrower, uint256 timestamp);

    /// @notice Emitted when a borrower is blocked
    event BorrowerBlocked(address indexed borrower, uint256 timestamp);

    /// @notice Emitted when a borrower is removed
    event BorrowerRemoved(address indexed borrower, uint256 timestamp);

    /// @notice Emitted when an investor is added
    event InvestorAdded(address indexed investor, uint256 timestamp);

    /// @notice Emitted when an investor is blocked
    event InvestorBlocked(address indexed investor, uint256 timestamp);

    /// @notice Emitted when an investor is removed
    event InvestorRemoved(address indexed investor, uint256 timestamp);

    /// @notice Emitted when a stablecoin is added to supported list
    event StablecoinAdded(address indexed stablecoin, uint256 timestamp);

    /// @notice Emitted when a stablecoin is removed from supported list
    event StablecoinRemoved(address indexed stablecoin, uint256 timestamp);

    /// @notice Emitted when tokens are deposited
    event TokensDeposited(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    /// @notice Emitted when tokens are withdrawn
    event TokensWithdrawn(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    /// @notice Emitted when tokens are transferred between users
    event TokensTransferred(
        address indexed from,
        address indexed to,
        address indexed token,
        uint256 amount,
        uint256 timestamp
    );

    /// @dev Custom errors for gas optimization
    error InvalidAddress();
    error ParticipantAlreadyExists();
    error ParticipantNotFound();
    error ParticipantBlocked();
    error ParticipantRemoved();
    error StablecoinNotSupported();
    error StablecoinAlreadySupported();
    error InsufficientBalance();
    error InvalidAmount();
    error TransferFailed();
    error InsufficientStake();

    /**
     * @notice Constructor to initialize the Web3 Thunder Finance Protocol
     * @dev Sets up the initial admin role and grants it to the deployer
     */
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        validatorStakeMinimum = 1 wei;
    }

    /**
     * @notice Adds a new validator to the protocol
     * @dev Only callable by admins, validator must not already exist and must stake minimum amount
     * @param _validator Address of the validator to add
     */
    function addValidator(address _validator) external payable onlyRole(ADMIN_ROLE) whenNotPaused {
        if (_validator == address(0)) revert InvalidAddress();
        if (participants[_validator].account != address(0)) revert ParticipantAlreadyExists();
        if (msg.value < validatorStakeMinimum) revert InsufficientStake();

        participants[_validator] = Participant({
            account: _validator,
            status: ParticipantStatus.Active,
            registeredAt: block.timestamp,
            updatedAt: block.timestamp,
            role: VALIDATOR_ROLE
        });

        validatorStakes[_validator] = msg.value;
        validators.push(_validator);
        _grantRole(VALIDATOR_ROLE, _validator);

        emit ValidatorStaked(_validator, msg.value, block.timestamp);
        emit ValidatorAdded(_validator, block.timestamp);
    }

    /**
     * @notice Blocks an existing validator
     * @dev Only callable by admins, validator must be active
     * @param _validator Address of the validator to block
     */
    function blockValidator(address _validator) external onlyRole(ADMIN_ROLE) {
        _checkParticipantExists(_validator);
        if (participants[_validator].status == ParticipantStatus.Blocked) revert ParticipantBlocked();

        participants[_validator].status = ParticipantStatus.Blocked;
        participants[_validator].updatedAt = block.timestamp;
        _revokeRole(VALIDATOR_ROLE, _validator);

        emit ValidatorBlocked(_validator, block.timestamp);
    }

    /**
     * @notice Removes a validator from the protocol
     * @dev Only callable by admins, marks validator as removed
     * @param _validator Address of the validator to remove
     */
    function removeValidator(address _validator) external onlyRole(ADMIN_ROLE) {
        _checkParticipantExists(_validator);

        participants[_validator].status = ParticipantStatus.Removed;
        participants[_validator].updatedAt = block.timestamp;
        _revokeRole(VALIDATOR_ROLE, _validator);

        emit ValidatorRemoved(_validator, block.timestamp);
    }

    /**
     * @notice Adds a new borrower to the protocol
     * @dev Only callable by admins, borrower must not already exist
     * @param _borrower Address of the borrower to add
     */
    function addBorrower(address _borrower) external onlyRole(ADMIN_ROLE) whenNotPaused {
        if (_borrower == address(0)) revert InvalidAddress();
        if (participants[_borrower].account != address(0)) revert ParticipantAlreadyExists();

        participants[_borrower] = Participant({
            account: _borrower,
            status: ParticipantStatus.Active,
            registeredAt: block.timestamp,
            updatedAt: block.timestamp,
            role: BORROWER_ROLE
        });

        borrowers.push(_borrower);
        _grantRole(BORROWER_ROLE, _borrower);

        emit BorrowerAdded(_borrower, block.timestamp);
    }

    /**
     * @notice Blocks an existing borrower
     * @dev Only callable by admins, borrower must be active
     * @param _borrower Address of the borrower to block
     */
    function blockBorrower(address _borrower) external onlyRole(ADMIN_ROLE) {
        _checkParticipantExists(_borrower);
        if (participants[_borrower].status == ParticipantStatus.Blocked) revert ParticipantBlocked();

        participants[_borrower].status = ParticipantStatus.Blocked;
        participants[_borrower].updatedAt = block.timestamp;
        _revokeRole(BORROWER_ROLE, _borrower);

        emit BorrowerBlocked(_borrower, block.timestamp);
    }

    /**
     * @notice Removes a borrower from the protocol
     * @dev Only callable by admins, marks borrower as removed
     * @param _borrower Address of the borrower to remove
     */
    function removeBorrower(address _borrower) external onlyRole(ADMIN_ROLE) {
        _checkParticipantExists(_borrower);

        participants[_borrower].status = ParticipantStatus.Removed;
        participants[_borrower].updatedAt = block.timestamp;
        _revokeRole(BORROWER_ROLE, _borrower);

        emit BorrowerRemoved(_borrower, block.timestamp);
    }

    /**
     * @notice Adds a new investor to the protocol
     * @dev Only callable by admins, investor must not already exist
     * @param _investor Address of the investor to add
     */
    function addInvestor(address _investor) external onlyRole(ADMIN_ROLE) whenNotPaused {
        if (_investor == address(0)) revert InvalidAddress();
        if (participants[_investor].account != address(0)) revert ParticipantAlreadyExists();

        participants[_investor] = Participant({
            account: _investor,
            status: ParticipantStatus.Active,
            registeredAt: block.timestamp,
            updatedAt: block.timestamp,
            role: INVESTOR_ROLE
        });

        investors.push(_investor);
        _grantRole(INVESTOR_ROLE, _investor);

        emit InvestorAdded(_investor, block.timestamp);
    }

    /**
     * @notice Blocks an existing investor
     * @dev Only callable by admins, investor must be active
     * @param _investor Address of the investor to block
     */
    function blockInvestor(address _investor) external onlyRole(ADMIN_ROLE) {
        _checkParticipantExists(_investor);
        if (participants[_investor].status == ParticipantStatus.Blocked) revert ParticipantBlocked();

        participants[_investor].status = ParticipantStatus.Blocked;
        participants[_investor].updatedAt = block.timestamp;
        _revokeRole(INVESTOR_ROLE, _investor);

        emit InvestorBlocked(_investor, block.timestamp);
    }

    /**
     * @notice Removes an investor from the protocol
     * @dev Only callable by admins, marks investor as removed
     * @param _investor Address of the investor to remove
     */
    function removeInvestor(address _investor) external onlyRole(ADMIN_ROLE) {
        _checkParticipantExists(_investor);

        participants[_investor].status = ParticipantStatus.Removed;
        participants[_investor].updatedAt = block.timestamp;
        _revokeRole(INVESTOR_ROLE, _investor);

        emit InvestorRemoved(_investor, block.timestamp);
    }

    /**
     * @notice Adds a stablecoin to the list of supported tokens
     * @dev Only callable by admins
     * @param _stablecoin Address of the stablecoin to add
     */
    function addSupportedStablecoin(address _stablecoin) external onlyRole(ADMIN_ROLE) {
        if (_stablecoin == address(0)) revert InvalidAddress();
        if (supportedStablecoins[_stablecoin]) revert StablecoinAlreadySupported();

        supportedStablecoins[_stablecoin] = true;
        stablecoinsList.push(_stablecoin);

        emit StablecoinAdded(_stablecoin, block.timestamp);
    }

    /**
     * @notice Removes a stablecoin from the list of supported tokens
     * @dev Only callable by admins
     * @param _stablecoin Address of the stablecoin to remove
     */
    function removeSupportedStablecoin(address _stablecoin) external onlyRole(ADMIN_ROLE) {
        if (!supportedStablecoins[_stablecoin]) revert StablecoinNotSupported();

        supportedStablecoins[_stablecoin] = false;

        emit StablecoinRemoved(_stablecoin, block.timestamp);
    }

    /**
     * @notice Deposits stablecoins into the protocol
     * @dev User must approve this contract to spend tokens first. Protected against reentrancy
     * @param _token Address of the stablecoin to deposit
     * @param _amount Amount of tokens to deposit
     */
    function deposit(address _token, uint256 _amount) 
        external 
        nonReentrant 
        whenNotPaused 
    {
        if (!supportedStablecoins[_token]) revert StablecoinNotSupported();
        if (_amount == 0) revert InvalidAmount();
        _checkParticipantActive(msg.sender);

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        balances[msg.sender][_token] += _amount;
        totalDeposits[_token] += _amount;

        emit TokensDeposited(msg.sender, _token, _amount, block.timestamp);
    }

    /**
     * @notice Withdraws stablecoins from the protocol
     * @dev Protected against reentrancy
     * @param _token Address of the stablecoin to withdraw
     * @param _amount Amount of tokens to withdraw
     */
    function withdraw(address _token, uint256 _amount) 
        external 
        nonReentrant 
        whenNotPaused 
    {
        if (!supportedStablecoins[_token]) revert StablecoinNotSupported();
        if (_amount == 0) revert InvalidAmount();
        if (balances[msg.sender][_token] < _amount) revert InsufficientBalance();
        _checkParticipantActive(msg.sender);

        balances[msg.sender][_token] -= _amount;
        totalDeposits[_token] -= _amount;

        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit TokensWithdrawn(msg.sender, _token, _amount, block.timestamp);
    }

    /**
     * @notice Transfers stablecoins between protocol participants
     * @dev Only callable by admins or validators. Protected against reentrancy
     * @param _from Address to transfer from
     * @param _to Address to transfer to
     * @param _token Address of the stablecoin to transfer
     * @param _amount Amount of tokens to transfer
     */
    function transferTokens(
        address _from,
        address _to,
        address _token,
        uint256 _amount
    ) external nonReentrant whenNotPaused {
        if (!hasRole(ADMIN_ROLE, msg.sender) && !hasRole(VALIDATOR_ROLE, msg.sender)) {
            revert("Unauthorized");
        }
        if (_to == address(0)) revert InvalidAddress();
        if (!supportedStablecoins[_token]) revert StablecoinNotSupported();
        if (_amount == 0) revert InvalidAmount();
        if (balances[_from][_token] < _amount) revert InsufficientBalance();
        _checkParticipantActive(_from);
        _checkParticipantActive(_to);

        balances[_from][_token] -= _amount;
        balances[_to][_token] += _amount;

        emit TokensTransferred(_from, _to, _token, _amount, block.timestamp);
    }

    /**
     * @notice Updates the minimum stake required for validators
     * @dev Only callable by admins
     * @param _newMinimum The new minimum stake amount in wei
     */
    function setValidatorStakeMinimum(uint256 _newMinimum) external onlyRole(ADMIN_ROLE) {
        uint256 oldMinimum = validatorStakeMinimum;
        validatorStakeMinimum = _newMinimum;
        emit ValidatorStakeMinimumUpdated(oldMinimum, _newMinimum, block.timestamp);
    }

    /**
     * @notice Pauses all protocol operations
     * @dev Only callable by admins
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses protocol operations
     * @dev Only callable by admins
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @notice Gets the balance of a user for a specific token
     * @param _user Address of the user
     * @param _token Address of the stablecoin
     * @return The balance amount
     */
    function getBalance(address _user, address _token) external view returns (uint256) {
        return balances[_user][_token];
    }

    /**
     * @notice Gets the total number of validators
     * @return The count of validators
     */
    function getValidatorsCount() external view returns (uint256) {
        return validators.length;
    }

    /**
     * @notice Gets the total number of borrowers
     * @return The count of borrowers
     */
    function getBorrowersCount() external view returns (uint256) {
        return borrowers.length;
    }

    /**
     * @notice Gets the total number of investors
     * @return The count of investors
     */
    function getInvestorsCount() external view returns (uint256) {
        return investors.length;
    }

    /**
     * @notice Gets the list of all supported stablecoins
     * @return Array of stablecoin addresses
     */
    function getSupportedStablecoins() external view returns (address[] memory) {
        return stablecoinsList;
    }

    /**
     * @notice Checks if a participant is active
     * @param _participant Address of the participant to check
     * @return True if participant is active, false otherwise
     */
    function isParticipantActive(address _participant) external view returns (bool) {
        return participants[_participant].account != address(0) && 
               participants[_participant].status == ParticipantStatus.Active;
    }

    /**
     * @notice Gets the staked amount for a validator
     * @param _validator Address of the validator
     * @return The staked amount in wei
     */
    function getValidatorStake(address _validator) external view returns (uint256) {
        return validatorStakes[_validator];
    }

    /**
     * @dev Internal function to check if participant exists
     * @param _participant Address of the participant
     */
    function _checkParticipantExists(address _participant) internal view {
        if (participants[_participant].account == address(0)) revert ParticipantNotFound();
    }

    /**
     * @dev Internal function to check if participant is active
     * @param _participant Address of the participant
     */
    function _checkParticipantActive(address _participant) internal view {
        _checkParticipantExists(_participant);
        if (participants[_participant].status == ParticipantStatus.Blocked) {
            revert ParticipantBlocked();
        }
        if (participants[_participant].status == ParticipantStatus.Removed) {
            revert ParticipantRemoved();
        }
    }
}
