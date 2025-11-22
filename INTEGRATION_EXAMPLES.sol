// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Web3ThunderFinanceProtocol Integration Examples
 * @notice Code examples for integrating with the Web3 Thunder Finance Protocol
 * @dev This file contains pseudo-code examples for common integration patterns
 */

/*

EXAMPLE 1: Setting Up the Protocol (Admin Operations)
=====================================================

// Deploy the contract
Web3ThunderFinanceProtocol protocol = new Web3ThunderFinanceProtocol();

// Add supported stablecoins
protocol.addSupportedStablecoin(USDC_ADDRESS);
protocol.addSupportedStablecoin(USDT_ADDRESS);
protocol.addSupportedStablecoin(DAI_ADDRESS);

// Add validators
protocol.addValidator(0x1234...); // Validator 1
protocol.addValidator(0x5678...); // Validator 2
protocol.addValidator(0x9abc...); // Validator 3

// Add initial borrowers
protocol.addBorrower(0xdef0...);
protocol.addBorrower(0x1111...);

// Add initial investors
protocol.addInvestor(0x2222...);
protocol.addInvestor(0x3333...);


EXAMPLE 2: Investor Deposits Liquidity
======================================

// Investor needs to approve the protocol first
IERC20 usdc = IERC20(USDC_ADDRESS);
uint256 depositAmount = 100_000 * 10**6; // 100k USDC

// Step 1: Approve
usdc.approve(address(protocol), depositAmount);

// Step 2: Deposit
protocol.deposit(USDC_ADDRESS, depositAmount);

// Check balance
uint256 balance = protocol.getBalance(msg.sender, USDC_ADDRESS);
// balance = 100,000 USDC


EXAMPLE 3: Admin Transfers Funds to Borrower
============================================

// Admin or Validator can transfer funds between participants
address investor = 0x2222...;
address borrower = 0xdef0...;
uint256 loanAmount = 50_000 * 10**6; // 50k USDC

protocol.transferTokens(
    investor,        // from
    borrower,        // to
    USDC_ADDRESS,    // token
    loanAmount       // amount
);

// Now borrower can withdraw if needed


EXAMPLE 4: Borrower Withdraws Loan
===================================

// Borrower withdraws the loan amount to their wallet
uint256 withdrawAmount = 50_000 * 10**6;

protocol.withdraw(USDC_ADDRESS, withdrawAmount);

// Funds are now in borrower's wallet


EXAMPLE 5: Emergency Pause
===========================

// In case of emergency, admin can pause the protocol
protocol.pause();

// All deposits, withdrawals, and transfers are now blocked

// After issue is resolved
protocol.unpause();


EXAMPLE 6: Managing Participants
=================================

// Block a suspicious participant
protocol.blockBorrower(0xdef0...);

// Participant can no longer deposit, withdraw, or receive transfers

// If needed, completely remove
protocol.removeBorrower(0xdef0...);


EXAMPLE 7: Query Functions
===========================

// Check if an address is active
bool isActive = protocol.isParticipantActive(0x2222...);

// Get participant counts
uint256 validatorCount = protocol.getValidatorsCount();
uint256 borrowerCount = protocol.getBorrowersCount();
uint256 investorCount = protocol.getInvestorsCount();

// Get supported stablecoins
address[] memory stablecoins = protocol.getSupportedStablecoins();

// Check role
bool isValidator = protocol.hasRole(protocol.VALIDATOR_ROLE(), 0x1234...);
bool isAdmin = protocol.hasRole(protocol.ADMIN_ROLE(), msg.sender);

// Get balance
uint256 balance = protocol.getBalance(investor, USDC_ADDRESS);

// Get total deposits for a token
uint256 totalDeposits = protocol.totalDeposits(USDC_ADDRESS);


EXAMPLE 8: Multi-Signature Integration (Recommended)
===================================================

// Using Gnosis Safe for admin operations
// Deploy Gnosis Safe with 3/5 multisig
GnosisSafe safe = new GnosisSafe();

// Grant admin role to the safe
protocol.grantRole(protocol.ADMIN_ROLE(), address(safe));

// Now all admin operations require 3 signatures
// This adds significant security to the protocol


EXAMPLE 9: Event Monitoring (Off-Chain)
========================================

// Listen for deposit events
protocol.on('TokensDeposited', (user, token, amount, timestamp) => {
    console.log(`${user} deposited ${amount} of ${token}`);
    // Update database
    // Send notification
    // Update analytics
});

// Listen for participant events
protocol.on('BorrowerAdded', (borrower, timestamp) => {
    console.log(`New borrower added: ${borrower}`);
    // Send welcome email
    // Update KYC database
});

// Listen for transfers
protocol.on('TokensTransferred', (from, to, token, amount, timestamp) => {
    console.log(`Transfer: ${amount} ${token} from ${from} to ${to}`);
    // Update loan records
    // Calculate interest
    // Trigger repayment schedule
});


EXAMPLE 10: Integration with Frontend (Web3.js)
==============================================

// Initialize Web3
const web3 = new Web3(window.ethereum);
const protocol = new web3.eth.Contract(ABI, PROTOCOL_ADDRESS);

// Connect wallet
await window.ethereum.request({ method: 'eth_requestAccounts' });

// Deposit function
async function deposit(tokenAddress, amount) {
    const accounts = await web3.eth.getAccounts();
    const token = new web3.eth.Contract(ERC20_ABI, tokenAddress);
    
    // Approve
    await token.methods
        .approve(PROTOCOL_ADDRESS, amount)
        .send({ from: accounts[0] });
    
    // Deposit
    await protocol.methods
        .deposit(tokenAddress, amount)
        .send({ from: accounts[0] });
}

// Withdraw function
async function withdraw(tokenAddress, amount) {
    const accounts = await web3.eth.getAccounts();
    
    await protocol.methods
        .withdraw(tokenAddress, amount)
        .send({ from: accounts[0] });
}

// Get balance
async function getBalance(userAddress, tokenAddress) {
    const balance = await protocol.methods
        .getBalance(userAddress, tokenAddress)
        .call();
    
    return balance;
}


EXAMPLE 11: Integration with Backend (ethers.js)
===============================================

import { ethers } from 'ethers';

// Setup provider and signer
const provider = new ethers.providers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const protocol = new ethers.Contract(PROTOCOL_ADDRESS, ABI, wallet);

// Admin adds investor
async function addInvestor(investorAddress) {
    const tx = await protocol.addInvestor(investorAddress);
    await tx.wait();
    console.log(`Investor ${investorAddress} added`);
}

// Query participant status
async function checkParticipant(address) {
    const isActive = await protocol.isParticipantActive(address);
    const balance = await protocol.getBalance(address, USDC_ADDRESS);
    
    return { isActive, balance };
}

// Transfer tokens (validator or admin)
async function transferFunds(from, to, token, amount) {
    const tx = await protocol.transferTokens(from, to, token, amount);
    const receipt = await tx.wait();
    
    console.log(`Transfer successful: ${receipt.transactionHash}`);
}


EXAMPLE 12: Access Control Pattern
===================================

// Best practice: Use modifiers in your integration contracts

contract Web3ThunderFinanceIntegration {
    Web3ThunderFinanceProtocol public protocol;
    
    modifier onlyActiveInvestor() {
        require(
            protocol.isParticipantActive(msg.sender),
            "Not an active investor"
        );
        require(
            protocol.hasRole(protocol.INVESTOR_ROLE(), msg.sender),
            "Not an investor"
        );
        _;
    }
    
    modifier onlyActiveBorrower() {
        require(
            protocol.isParticipantActive(msg.sender),
            "Not an active borrower"
        );
        require(
            protocol.hasRole(protocol.BORROWER_ROLE(), msg.sender),
            "Not a borrower"
        );
        _;
    }
    
    function depositAsInvestor(address token, uint256 amount) 
        external 
        onlyActiveInvestor 
    {
        // Your logic here
        protocol.deposit(token, amount);
    }
}


EXAMPLE 13: Testing with Foundry
=================================

// test/MyIntegration.t.sol
contract MyIntegrationTest is Test {
    Web3ThunderFinanceProtocol protocol;
    MockERC20 usdc;
    
    address admin = address(1);
    address investor = address(2);
    
    function setUp() public {
        vm.startPrank(admin);
        protocol = new Web3ThunderFinanceProtocol();
        usdc = new MockERC20("USDC", "USDC", 6);
        
        protocol.addSupportedStablecoin(address(usdc));
        protocol.addInvestor(investor);
        vm.stopPrank();
        
        usdc.mint(investor, 1_000_000 * 10**6);
    }
    
    function testInvestorDeposit() public {
        uint256 amount = 100_000 * 10**6;
        
        vm.startPrank(investor);
        usdc.approve(address(protocol), amount);
        protocol.deposit(address(usdc), amount);
        vm.stopPrank();
        
        assertEq(protocol.getBalance(investor, address(usdc)), amount);
    }
}


EXAMPLE 14: Error Handling
===========================

// Proper error handling in your integration

try protocol.deposit(tokenAddress, amount) {
    // Success
    emit DepositSuccessful(msg.sender, amount);
} catch Error(string memory reason) {
    // Revert with reason
    emit DepositFailed(msg.sender, amount, reason);
    revert(reason);
} catch (bytes memory lowLevelData) {
    // Low level error
    emit DepositFailed(msg.sender, amount, "Unknown error");
    revert("Deposit failed");
}


EXAMPLE 15: Gas Optimization Tips
==================================

// Cache protocol calls in memory
address[] memory stablecoins = protocol.getSupportedStablecoins();
uint256 stablecoinCount = stablecoins.length;

// Use this cached data instead of calling again
for (uint256 i = 0; i < stablecoinCount; i++) {
    address token = stablecoins[i];
    uint256 balance = protocol.getBalance(user, token);
    // Process balance
}

// Instead of calling protocol.getBalance multiple times in loop

*/
