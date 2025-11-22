# Web3 Thunder Finance Protocol - Smart Contracts

## Overview

The Web3 Thunder Finance Protocol is a decentralized credit protocol built on Ethereum using Solidity 0.8.19. This repository contains the main smart contract that manages participants (validators, borrowers, and investors) and handles ERC20 stablecoin transfers.

## Features

### Participant Management
- **Validators**: Can verify and approve transactions
- **Borrowers**: Can request and receive loans
- **Investors**: Can provide liquidity to the protocol

### Access Control
- Role-based access control using OpenZeppelin's AccessControl
- Admin role for protocol management
- Granular permissions for each participant type

### Token Management
- Support for multiple ERC20 stablecoins
- Secure deposit and withdrawal functionality
- Internal balance tracking per user per token
- Admin/Validator controlled transfers

### Security Features
- **ReentrancyGuard**: Protects against reentrancy attacks
- **Pausable**: Emergency pause functionality
- **SafeERC20**: Safe token transfer operations
- **Custom Errors**: Gas-efficient error handling
- **Event Logging**: Comprehensive event emission for transparency

## Smart Contracts

### Web3ThunderFinanceProtocol.sol
Main protocol contract that handles:
- Participant registration and management
- Stablecoin deposits and withdrawals
- Internal transfers between participants
- Protocol pause/unpause functionality

### MockERC20.sol
Mock ERC20 token for testing purposes

## Installation

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/) (optional, for additional tooling)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd smartcontractsandcircuits
```

2. Install dependencies:
```bash
forge install
```

3. Compile contracts:
```bash
forge build
```

## Testing

The project includes comprehensive test coverage including:
- Unit tests for all functions
- Integration tests for complex workflows
- Fuzz tests for edge cases
- Reentrancy protection tests

### Run Tests

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vv

# Run specific test
forge test --match-test testAddValidator

# Run with gas reporting
forge test --gas-report

# Run with coverage
forge coverage
```

### Test Results
All 34 tests pass successfully, covering:
- ✅ Validator management
- ✅ Borrower management
- ✅ Investor management
- ✅ Stablecoin management
- ✅ Deposit functionality
- ✅ Withdrawal functionality
- ✅ Transfer functionality
- ✅ Pause/Unpause functionality
- ✅ Access control
- ✅ Security protections

## Deployment

### Local Deployment (Anvil)

1. Start local node:
```bash
anvil
```

2. Deploy contract:
```bash
forge script script/DeployWeb3ThunderFinanceProtocol.s.sol:DeployWeb3ThunderFinanceProtocol --rpc-url http://localhost:8545 --broadcast
```

### Testnet/Mainnet Deployment

1. Set up environment variables:
```bash
export PRIVATE_KEY=your_private_key
export RPC_URL=your_rpc_url
export ETHERSCAN_API_KEY=your_etherscan_api_key
```

2. Deploy and verify:
```bash
forge script script/DeployWeb3ThunderFinanceProtocol.s.sol:DeployWeb3ThunderFinanceProtocol \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify
```

## Usage

### Adding Participants

```solidity
// Add a validator
protocol.addValidator(validatorAddress);

// Add a borrower
protocol.addBorrower(borrowerAddress);

// Add an investor
protocol.addInvestor(investorAddress);
```

### Managing Stablecoins

```solidity
// Add supported stablecoin
protocol.addSupportedStablecoin(usdcAddress);

// Remove stablecoin
protocol.removeSupportedStablecoin(usdcAddress);
```

### Depositing and Withdrawing

```solidity
// Approve token first
IERC20(usdc).approve(protocolAddress, amount);

// Deposit
protocol.deposit(usdcAddress, amount);

// Withdraw
protocol.withdraw(usdcAddress, amount);
```

### Transferring Tokens (Admin/Validator Only)

```solidity
protocol.transferTokens(fromAddress, toAddress, tokenAddress, amount);
```

## Security Considerations

### Implemented Protections

1. **Reentrancy Protection**: All state-changing functions that interact with external contracts use the `nonReentrant` modifier
2. **Access Control**: Role-based permissions ensure only authorized addresses can perform sensitive operations
3. **Pausability**: Emergency pause mechanism to halt all operations if needed
4. **Safe Math**: Solidity 0.8.19 has built-in overflow/underflow protection
5. **SafeERC20**: Uses OpenZeppelin's SafeERC20 library for secure token operations
6. **Input Validation**: Comprehensive checks for zero addresses, zero amounts, and invalid states
7. **Custom Errors**: Gas-efficient error handling
8. **Events**: All state changes emit events for transparency and monitoring

### Best Practices Followed

- ✅ Checks-Effects-Interactions pattern
- ✅ Pull over push for withdrawals
- ✅ Fail-safe modes (pausable)
- ✅ Comprehensive NatSpec documentation
- ✅ No delegate calls to untrusted contracts
- ✅ Explicit visibility for all functions
- ✅ No floating pragma versions

### Recommended Audits

Before mainnet deployment, consider:
1. Professional security audit
2. Formal verification of critical functions
3. Bug bounty program
4. Testnet deployment and testing period

## Gas Optimization

The contract implements several gas optimization techniques:
- Custom errors instead of strings
- Efficient storage packing
- Minimal storage reads/writes
- Use of `calldata` where appropriate

## Contract Architecture

```
Web3ThunderFinanceProtocol
├── AccessControl (role management)
├── ReentrancyGuard (reentrancy protection)
└── Pausable (emergency pause)
```

### Roles
- `DEFAULT_ADMIN_ROLE`: Can grant/revoke all roles
- `ADMIN_ROLE`: Can manage participants and protocol settings
- `VALIDATOR_ROLE`: Can validate transactions and transfer tokens
- `BORROWER_ROLE`: Can participate as borrower
- `INVESTOR_ROLE`: Can participate as investor

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

- **Project**: Web3 Thunder Finance Protocol
- **Security Contact**: security@web3thunderfinance.io
- **Website**: [Coming Soon]

## Acknowledgments

- OpenZeppelin for secure contract libraries
- Foundry for development framework
- The Ethereum community for best practices and security guidelines
