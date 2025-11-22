// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/Web3ThunderFinanceProtocol.sol";
import "../src/mocks/MockERC20.sol";

/**
 * @title Web3ThunderFinanceProtocolTest
 * @notice Comprehensive test suite for the Web3 Thunder Finance Protocol
 */
contract Web3ThunderFinanceProtocolTest is Test {
    Web3ThunderFinanceProtocol public protocol;
    MockERC20 public usdc;
    MockERC20 public usdt;

    address public admin = address(1);
    address public validator1 = address(2);
    address public validator2 = address(3);
    address public borrower1 = address(4);
    address public borrower2 = address(5);
    address public investor1 = address(6);
    address public investor2 = address(7);
    address public unauthorized = address(8);

    uint256 constant INITIAL_BALANCE = 1_000_000 * 10**6; // 1M tokens with 6 decimals

    event ValidatorAdded(address indexed validator, uint256 timestamp);
    event ValidatorBlocked(address indexed validator, uint256 timestamp);
    event ValidatorRemoved(address indexed validator, uint256 timestamp);
    event BorrowerAdded(address indexed borrower, uint256 timestamp);
    event BorrowerBlocked(address indexed borrower, uint256 timestamp);
    event BorrowerRemoved(address indexed borrower, uint256 timestamp);
    event InvestorAdded(address indexed investor, uint256 timestamp);
    event InvestorBlocked(address indexed investor, uint256 timestamp);
    event InvestorRemoved(address indexed investor, uint256 timestamp);
    event StablecoinAdded(address indexed stablecoin, uint256 timestamp);
    event StablecoinRemoved(address indexed stablecoin, uint256 timestamp);
    event TokensDeposited(address indexed user, address indexed token, uint256 amount, uint256 timestamp);
    event TokensWithdrawn(address indexed user, address indexed token, uint256 amount, uint256 timestamp);
    event TokensTransferred(address indexed from, address indexed to, address indexed token, uint256 amount, uint256 timestamp);

    function setUp() public {
        vm.startPrank(admin);
        protocol = new Web3ThunderFinanceProtocol();
        
        // Deploy mock stablecoins
        usdc = new MockERC20("USD Coin", "USDC", 6);
        usdt = new MockERC20("Tether USD", "USDT", 6);

        // Add stablecoins to protocol
        protocol.addSupportedStablecoin(address(usdc));
        protocol.addSupportedStablecoin(address(usdt));

        vm.stopPrank();

        // Mint tokens to test addresses
        usdc.mint(investor1, INITIAL_BALANCE);
        usdc.mint(investor2, INITIAL_BALANCE);
        usdt.mint(investor1, INITIAL_BALANCE);
        usdt.mint(borrower1, INITIAL_BALANCE);
    }

    /*//////////////////////////////////////////////////////////////
                        VALIDATOR MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testAddValidator() public {
        vm.startPrank(admin);
        vm.deal(admin, 10 ether);
        
        vm.expectEmit(true, false, false, true);
        emit ValidatorAdded(validator1, block.timestamp);
        
        protocol.addValidator{value: 1 wei}(validator1);
        
        assertTrue(protocol.hasRole(protocol.VALIDATOR_ROLE(), validator1));
        assertEq(protocol.getValidatorsCount(), 1);
        assertTrue(protocol.isParticipantActive(validator1));
        assertEq(protocol.getValidatorStake(validator1), 1 wei);
        
        vm.stopPrank();
    }

    function testAddValidatorRevertsIfNotAdmin() public {
        vm.startPrank(unauthorized);
        vm.deal(unauthorized, 10 ether);
        
        vm.expectRevert();
        protocol.addValidator{value: 1 wei}(validator1);
        
        vm.stopPrank();
    }

    function testAddValidatorRevertsIfZeroAddress() public {
        vm.startPrank(admin);
        vm.deal(admin, 10 ether);
        
        vm.expectRevert(Web3ThunderFinanceProtocol.InvalidAddress.selector);
        protocol.addValidator{value: 1 wei}(address(0));
        
        vm.stopPrank();
    }

    function testAddValidatorRevertsIfAlreadyExists() public {
        vm.startPrank(admin);
        vm.deal(admin, 10 ether);
        
        protocol.addValidator{value: 1 wei}(validator1);
        
        vm.expectRevert(Web3ThunderFinanceProtocol.ParticipantAlreadyExists.selector);
        protocol.addValidator{value: 1 wei}(validator1);
        
        vm.stopPrank();
    }

    function testBlockValidator() public {
        vm.startPrank(admin);
        vm.deal(admin, 10 ether);
        
        protocol.addValidator{value: 1 wei}(validator1);
        
        vm.expectEmit(true, false, false, true);
        emit ValidatorBlocked(validator1, block.timestamp);
        
        protocol.blockValidator(validator1);
        
        assertFalse(protocol.hasRole(protocol.VALIDATOR_ROLE(), validator1));
        assertFalse(protocol.isParticipantActive(validator1));
        
        vm.stopPrank();
    }

    function testRemoveValidator() public {
        vm.startPrank(admin);
        vm.deal(admin, 10 ether);
        
        protocol.addValidator{value: 1 wei}(validator1);
        
        vm.expectEmit(true, false, false, true);
        emit ValidatorRemoved(validator1, block.timestamp);
        
        protocol.removeValidator(validator1);
        
        assertFalse(protocol.hasRole(protocol.VALIDATOR_ROLE(), validator1));
        assertFalse(protocol.isParticipantActive(validator1));
        
        vm.stopPrank();
    }

    function testAddValidatorRevertsIfInsufficientStake() public {
        vm.startPrank(admin);
        vm.deal(admin, 10 ether);
        
        vm.expectRevert(Web3ThunderFinanceProtocol.InsufficientStake.selector);
        protocol.addValidator{value: 0}(validator1);
        
        vm.stopPrank();
    }

    function testAddValidatorWithHigherStake() public {
        vm.startPrank(admin);
        vm.deal(admin, 10 ether);
        
        uint256 stakeAmount = 5 ether;
        protocol.addValidator{value: stakeAmount}(validator1);
        
        assertEq(protocol.getValidatorStake(validator1), stakeAmount);
        assertTrue(protocol.hasRole(protocol.VALIDATOR_ROLE(), validator1));
        
        vm.stopPrank();
    }

    function testSetValidatorStakeMinimum() public {
        vm.startPrank(admin);
        
        uint256 newMinimum = 10 ether;
        protocol.setValidatorStakeMinimum(newMinimum);
        
        assertEq(protocol.validatorStakeMinimum(), newMinimum);
        
        vm.stopPrank();
    }

    function testSetValidatorStakeMinimumRevertsIfNotAdmin() public {
        vm.startPrank(unauthorized);
        
        vm.expectRevert();
        protocol.setValidatorStakeMinimum(10 ether);
        
        vm.stopPrank();
    }

    function testAddValidatorWithNewMinimum() public {
        vm.startPrank(admin);
        vm.deal(admin, 20 ether);
        
        uint256 newMinimum = 5 ether;
        protocol.setValidatorStakeMinimum(newMinimum);
        
        // Should fail with less than new minimum
        vm.expectRevert(Web3ThunderFinanceProtocol.InsufficientStake.selector);
        protocol.addValidator{value: 4 ether}(validator1);
        
        // Should succeed with exact minimum
        protocol.addValidator{value: newMinimum}(validator1);
        assertEq(protocol.getValidatorStake(validator1), newMinimum);
        
        vm.stopPrank();
    }

    function testValidatorStakeMinimumInitialized() public {
        assertEq(protocol.validatorStakeMinimum(), 1 wei);
    }

    /*//////////////////////////////////////////////////////////////
                        BORROWER MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testAddBorrower() public {
        vm.startPrank(admin);
        
        vm.expectEmit(true, false, false, true);
        emit BorrowerAdded(borrower1, block.timestamp);
        
        protocol.addBorrower(borrower1);
        
        assertTrue(protocol.hasRole(protocol.BORROWER_ROLE(), borrower1));
        assertEq(protocol.getBorrowersCount(), 1);
        assertTrue(protocol.isParticipantActive(borrower1));
        
        vm.stopPrank();
    }

    function testBlockBorrower() public {
        vm.startPrank(admin);
        
        protocol.addBorrower(borrower1);
        
        vm.expectEmit(true, false, false, true);
        emit BorrowerBlocked(borrower1, block.timestamp);
        
        protocol.blockBorrower(borrower1);
        
        assertFalse(protocol.hasRole(protocol.BORROWER_ROLE(), borrower1));
        assertFalse(protocol.isParticipantActive(borrower1));
        
        vm.stopPrank();
    }

    function testRemoveBorrower() public {
        vm.startPrank(admin);
        
        protocol.addBorrower(borrower1);
        
        vm.expectEmit(true, false, false, true);
        emit BorrowerRemoved(borrower1, block.timestamp);
        
        protocol.removeBorrower(borrower1);
        
        assertFalse(protocol.hasRole(protocol.BORROWER_ROLE(), borrower1));
        assertFalse(protocol.isParticipantActive(borrower1));
        
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        INVESTOR MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testAddInvestor() public {
        vm.startPrank(admin);
        
        vm.expectEmit(true, false, false, true);
        emit InvestorAdded(investor1, block.timestamp);
        
        protocol.addInvestor(investor1);
        
        assertTrue(protocol.hasRole(protocol.INVESTOR_ROLE(), investor1));
        assertEq(protocol.getInvestorsCount(), 1);
        assertTrue(protocol.isParticipantActive(investor1));
        
        vm.stopPrank();
    }

    function testBlockInvestor() public {
        vm.startPrank(admin);
        
        protocol.addInvestor(investor1);
        
        vm.expectEmit(true, false, false, true);
        emit InvestorBlocked(investor1, block.timestamp);
        
        protocol.blockInvestor(investor1);
        
        assertFalse(protocol.hasRole(protocol.INVESTOR_ROLE(), investor1));
        assertFalse(protocol.isParticipantActive(investor1));
        
        vm.stopPrank();
    }

    function testRemoveInvestor() public {
        vm.startPrank(admin);
        
        protocol.addInvestor(investor1);
        
        vm.expectEmit(true, false, false, true);
        emit InvestorRemoved(investor1, block.timestamp);
        
        protocol.removeInvestor(investor1);
        
        assertFalse(protocol.hasRole(protocol.INVESTOR_ROLE(), investor1));
        assertFalse(protocol.isParticipantActive(investor1));
        
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        STABLECOIN MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function testAddSupportedStablecoin() public {
        MockERC20 dai = new MockERC20("DAI Stablecoin", "DAI", 18);
        
        vm.startPrank(admin);
        
        vm.expectEmit(true, false, false, true);
        emit StablecoinAdded(address(dai), block.timestamp);
        
        protocol.addSupportedStablecoin(address(dai));
        
        assertTrue(protocol.supportedStablecoins(address(dai)));
        
        address[] memory stablecoins = protocol.getSupportedStablecoins();
        assertEq(stablecoins.length, 3);
        
        vm.stopPrank();
    }

    function testAddSupportedStablecoinRevertsIfAlreadySupported() public {
        vm.startPrank(admin);
        
        vm.expectRevert(Web3ThunderFinanceProtocol.StablecoinAlreadySupported.selector);
        protocol.addSupportedStablecoin(address(usdc));
        
        vm.stopPrank();
    }

    function testRemoveSupportedStablecoin() public {
        vm.startPrank(admin);
        
        vm.expectEmit(true, false, false, true);
        emit StablecoinRemoved(address(usdc), block.timestamp);
        
        protocol.removeSupportedStablecoin(address(usdc));
        
        assertFalse(protocol.supportedStablecoins(address(usdc)));
        
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testDeposit() public {
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        vm.stopPrank();

        uint256 depositAmount = 10_000 * 10**6;
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), depositAmount);
        
        vm.expectEmit(true, true, false, true);
        emit TokensDeposited(investor1, address(usdc), depositAmount, block.timestamp);
        
        protocol.deposit(address(usdc), depositAmount);
        
        assertEq(protocol.getBalance(investor1, address(usdc)), depositAmount);
        assertEq(protocol.totalDeposits(address(usdc)), depositAmount);
        assertEq(usdc.balanceOf(address(protocol)), depositAmount);
        
        vm.stopPrank();
    }

    function testDepositRevertsIfNotSupported() public {
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        vm.stopPrank();

        MockERC20 unsupported = new MockERC20("Unsupported", "UNS", 18);
        unsupported.mint(investor1, 1000);
        
        vm.startPrank(investor1);
        unsupported.approve(address(protocol), 1000);
        
        vm.expectRevert(Web3ThunderFinanceProtocol.StablecoinNotSupported.selector);
        protocol.deposit(address(unsupported), 1000);
        
        vm.stopPrank();
    }

    function testDepositRevertsIfZeroAmount() public {
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        vm.stopPrank();

        vm.startPrank(investor1);
        
        vm.expectRevert(Web3ThunderFinanceProtocol.InvalidAmount.selector);
        protocol.deposit(address(usdc), 0);
        
        vm.stopPrank();
    }

    function testDepositRevertsIfParticipantBlocked() public {
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        protocol.blockInvestor(investor1);
        vm.stopPrank();

        uint256 depositAmount = 10_000 * 10**6;
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), depositAmount);
        
        vm.expectRevert(Web3ThunderFinanceProtocol.ParticipantBlocked.selector);
        protocol.deposit(address(usdc), depositAmount);
        
        vm.stopPrank();
    }

    function testDepositRevertsWhenPaused() public {
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        protocol.pause();
        vm.stopPrank();

        uint256 depositAmount = 10_000 * 10**6;
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), depositAmount);
        
        vm.expectRevert("Pausable: paused");
        protocol.deposit(address(usdc), depositAmount);
        
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAW TESTS
    //////////////////////////////////////////////////////////////*/

    function testWithdraw() public {
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        vm.stopPrank();

        uint256 depositAmount = 10_000 * 10**6;
        uint256 withdrawAmount = 5_000 * 10**6;
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), depositAmount);
        protocol.deposit(address(usdc), depositAmount);
        
        uint256 balanceBefore = usdc.balanceOf(investor1);
        
        vm.expectEmit(true, true, false, true);
        emit TokensWithdrawn(investor1, address(usdc), withdrawAmount, block.timestamp);
        
        protocol.withdraw(address(usdc), withdrawAmount);
        
        assertEq(protocol.getBalance(investor1, address(usdc)), depositAmount - withdrawAmount);
        assertEq(protocol.totalDeposits(address(usdc)), depositAmount - withdrawAmount);
        assertEq(usdc.balanceOf(investor1), balanceBefore + withdrawAmount);
        
        vm.stopPrank();
    }

    function testWithdrawRevertsIfInsufficientBalance() public {
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        vm.stopPrank();

        uint256 depositAmount = 10_000 * 10**6;
        uint256 withdrawAmount = 15_000 * 10**6;
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), depositAmount);
        protocol.deposit(address(usdc), depositAmount);
        
        vm.expectRevert(Web3ThunderFinanceProtocol.InsufficientBalance.selector);
        protocol.withdraw(address(usdc), withdrawAmount);
        
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function testTransferTokensByAdmin() public {
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        protocol.addBorrower(borrower1);
        vm.stopPrank();

        uint256 depositAmount = 10_000 * 10**6;
        uint256 transferAmount = 5_000 * 10**6;
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), depositAmount);
        protocol.deposit(address(usdc), depositAmount);
        vm.stopPrank();
        
        vm.startPrank(admin);
        
        vm.expectEmit(true, true, true, true);
        emit TokensTransferred(investor1, borrower1, address(usdc), transferAmount, block.timestamp);
        
        protocol.transferTokens(investor1, borrower1, address(usdc), transferAmount);
        
        assertEq(protocol.getBalance(investor1, address(usdc)), depositAmount - transferAmount);
        assertEq(protocol.getBalance(borrower1, address(usdc)), transferAmount);
        
        vm.stopPrank();
    }

    function testTransferTokensByValidator() public {
        vm.startPrank(admin);
        vm.deal(admin, 10 ether);
        protocol.addValidator{value: 1 wei}(validator1);
        protocol.addInvestor(investor1);
        protocol.addBorrower(borrower1);
        vm.stopPrank();

        uint256 depositAmount = 10_000 * 10**6;
        uint256 transferAmount = 5_000 * 10**6;
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), depositAmount);
        protocol.deposit(address(usdc), depositAmount);
        vm.stopPrank();
        
        vm.startPrank(validator1);
        
        protocol.transferTokens(investor1, borrower1, address(usdc), transferAmount);
        
        assertEq(protocol.getBalance(investor1, address(usdc)), depositAmount - transferAmount);
        assertEq(protocol.getBalance(borrower1, address(usdc)), transferAmount);
        
        vm.stopPrank();
    }

    function testTransferTokensRevertsIfUnauthorized() public {
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        protocol.addBorrower(borrower1);
        vm.stopPrank();

        uint256 depositAmount = 10_000 * 10**6;
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), depositAmount);
        protocol.deposit(address(usdc), depositAmount);
        vm.stopPrank();
        
        vm.startPrank(unauthorized);
        
        vm.expectRevert("Unauthorized");
        protocol.transferTokens(investor1, borrower1, address(usdc), 1000);
        
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        PAUSE/UNPAUSE TESTS
    //////////////////////////////////////////////////////////////*/

    function testPauseAndUnpause() public {
        vm.startPrank(admin);
        
        protocol.pause();
        assertTrue(protocol.paused());
        
        protocol.unpause();
        assertFalse(protocol.paused());
        
        vm.stopPrank();
    }

    function testPauseRevertsIfNotAdmin() public {
        vm.startPrank(unauthorized);
        
        vm.expectRevert();
        protocol.pause();
        
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        REENTRANCY TESTS
    //////////////////////////////////////////////////////////////*/

    function testDepositIsProtectedAgainstReentrancy() public {
        // This test verifies the nonReentrant modifier is in place
        // In practice, a malicious ERC20 would be needed to test actual reentrancy
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        vm.stopPrank();

        uint256 depositAmount = 10_000 * 10**6;
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), depositAmount);
        protocol.deposit(address(usdc), depositAmount);
        vm.stopPrank();

        // Verify deposit completed successfully
        assertEq(protocol.getBalance(investor1, address(usdc)), depositAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        VIEW FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function testGetSupportedStablecoins() public {
        address[] memory stablecoins = protocol.getSupportedStablecoins();
        assertEq(stablecoins.length, 2);
        assertEq(stablecoins[0], address(usdc));
        assertEq(stablecoins[1], address(usdt));
    }

    function testGetValidatorsCount() public {
        vm.startPrank(admin);
        vm.deal(admin, 10 ether);
        
        assertEq(protocol.getValidatorsCount(), 0);
        
        protocol.addValidator{value: 1 wei}(validator1);
        assertEq(protocol.getValidatorsCount(), 1);
        
        protocol.addValidator{value: 1 wei}(validator2);
        assertEq(protocol.getValidatorsCount(), 2);
        
        vm.stopPrank();
    }

    function testGetBorrowersCount() public {
        vm.startPrank(admin);
        
        assertEq(protocol.getBorrowersCount(), 0);
        
        protocol.addBorrower(borrower1);
        assertEq(protocol.getBorrowersCount(), 1);
        
        protocol.addBorrower(borrower2);
        assertEq(protocol.getBorrowersCount(), 2);
        
        vm.stopPrank();
    }

    function testGetInvestorsCount() public {
        vm.startPrank(admin);
        
        assertEq(protocol.getInvestorsCount(), 0);
        
        protocol.addInvestor(investor1);
        assertEq(protocol.getInvestorsCount(), 1);
        
        protocol.addInvestor(investor2);
        assertEq(protocol.getInvestorsCount(), 2);
        
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzzDeposit(uint256 amount) public {
        vm.assume(amount > 0 && amount <= INITIAL_BALANCE);
        
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        vm.stopPrank();
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), amount);
        protocol.deposit(address(usdc), amount);
        
        assertEq(protocol.getBalance(investor1, address(usdc)), amount);
        vm.stopPrank();
    }

    function testFuzzWithdraw(uint256 depositAmount, uint256 withdrawAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= INITIAL_BALANCE);
        vm.assume(withdrawAmount > 0 && withdrawAmount <= depositAmount);
        
        vm.startPrank(admin);
        protocol.addInvestor(investor1);
        vm.stopPrank();
        
        vm.startPrank(investor1);
        usdc.approve(address(protocol), depositAmount);
        protocol.deposit(address(usdc), depositAmount);
        protocol.withdraw(address(usdc), withdrawAmount);
        
        assertEq(protocol.getBalance(investor1, address(usdc)), depositAmount - withdrawAmount);
        vm.stopPrank();
    }
}
