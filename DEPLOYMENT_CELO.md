# Deprecated Deployment Guide - Legacy Protocol (Celo)

This guide referenced the legacy `Web3ThunderFinanceProtocol`. The protocol has been replaced by the mixer architecture.
Use the mixer deployment scripts instead (e.g. `DeployWeb3ThunderFinanceMixer.s.sol`). Retained for historical reference.

## Prerequisites

1. **Foundry installed** - Ensure you have Forge installed
2. **Private Key** - Have your deployment wallet private key ready
3. **CELO tokens** - Ensure your wallet has sufficient CELO for gas fees
4. **CeloScan API Key** - Get your API key from [CeloScan](https://celoscan.io/myapikey)

## Setup

### 1. Configure Environment Variables

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:

```bash
# Your deployment wallet private key (without 0x prefix)
PRIVATE_KEY=your_actual_private_key_here

# CeloScan API key for contract verification
CELOSCAN_API_KEY=your_celoscan_api_key_here
ETHERSCAN_API_KEY=your_celoscan_api_key_here

# Network selection
NETWORK=testnet  # or mainnet

# Optional: Set validator stake minimum (in wei)
VALIDATOR_STAKE_MINIMUM=1000000000000000000  # 1 CELO
```

### 2. Load Environment Variables

```bash
source .env
```

## Deployment

### Deploy to Celo Alfajores Testnet

```bash
forge script script/DeployWeb3ThunderFinanceToCelo.s.sol:DeployWeb3ThunderFinanceToCelo \
  --rpc-url alfajores \
  --broadcast \
  --verify \
  --etherscan-api-key $CELOSCAN_API_KEY \
  -vvvv
```

### Deploy to Celo Mainnet

⚠️ **WARNING: This deploys to production. Ensure you've thoroughly tested on testnet first!**

```bash
forge script script/DeployWeb3ThunderFinanceToCelo.s.sol:DeployWeb3ThunderFinanceToCelo \
  --rpc-url celo \
  --broadcast \
  --verify \
  --etherscan-api-key $CELOSCAN_API_KEY \
  -vvvv
```

## Verification

The deployment script uses Etherscan v2 API for automatic verification via CeloScan. The configuration in `foundry.toml` defines the custom chain aliases (`alfajores` and `celo`) with their respective API endpoints.

If automatic verification fails during deployment, you can verify manually:

### (Legacy) Manual Verification on Alfajores

```bash
forge verify-contract \
  --rpc-url alfajores \
  --etherscan-api-key $CELOSCAN_API_KEY \
  --watch \
  <CONTRACT_ADDRESS> \
  src/Web3ThunderFinanceProtocol.sol:Web3ThunderFinanceProtocol
```

### (Legacy) Manual Verification on Mainnet

```bash
forge verify-contract \
  --rpc-url celo \
  --etherscan-api-key $CELOSCAN_API_KEY \
  --watch \
  <CONTRACT_ADDRESS> \
  src/Web3ThunderFinanceProtocol.sol:Web3ThunderFinanceProtocol
```

**Note:** The verification uses the chain aliases defined in `foundry.toml` which automatically configures:
- Chain ID (44787 for Alfajores, 42220 for Mainnet)
- CeloScan API endpoints
- Compiler settings (Solidity 0.8.19, 200 optimizer runs)

## Post-Deployment

### 1. Save Contract Address

Update your `.env` file with the deployed contract address:

```bash
WEB3_THUNDER_FINANCE_PROTOCOL_ADDRESS=0x...
```

### (Legacy) 2. Initial Configuration

After legacy protocol deployment (no longer recommended), you could:

1. **Add supported stablecoins** (e.g., cUSD, cEUR, cREAL)
   ```bash
   cast send <PROTOCOL_ADDRESS> \
     "addSupportedStablecoin(address)" <STABLECOIN_ADDRESS> \
     --rpc-url $CELO_ALFAJORES_RPC_URL \
     --private-key $PRIVATE_KEY
   ```

2. **Add validators**
   ```bash
   cast send <PROTOCOL_ADDRESS> \
     "addValidator(address)" <VALIDATOR_ADDRESS> \
     --value 1ether \
     --rpc-url $CELO_ALFAJORES_RPC_URL \
     --private-key $PRIVATE_KEY
   ```

3. **Add borrowers and investors**
   ```bash
   cast send <PROTOCOL_ADDRESS> \
     "addBorrower(address)" <BORROWER_ADDRESS> \
     --rpc-url $CELO_ALFAJORES_RPC_URL \
     --private-key $PRIVATE_KEY

   cast send <PROTOCOL_ADDRESS> \
     "addInvestor(address)" <INVESTOR_ADDRESS> \
     --rpc-url $CELO_ALFAJORES_RPC_URL \
     --private-key $PRIVATE_KEY
   ```

## Network Information

### Celo Alfajores Testnet
- **Chain ID:** 44787
- **RPC URL:** https://alfajores-forno.celo-testnet.org
- **Block Explorer:** https://alfajores.celoscan.io
- **Faucet:** https://faucet.celo.org

### Celo Mainnet
- **Chain ID:** 42220
- **RPC URL:** https://forno.celo.org
- **Block Explorer:** https://celoscan.io

## Common Celo Stablecoins

### Alfajores Testnet
- **cUSD:** 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1
- **cEUR:** 0x10c892A6EC43a53E45D0B916B4b7D383B1b78C0F
- **cREAL:** 0xE4D517785D091D3c54818832dB6094bcc2744545

### Mainnet
- **cUSD:** 0x765DE816845861e75A25fCA122bb6898B8B1282a
- **cEUR:** 0xD8763CBa276a3738E6DE85b4b3bF5FDed6D6cA73
- **cREAL:** 0xe8537a3d056DA446677B9E9d6c5dB704EaAb4787

## Troubleshooting

### Insufficient Gas
Ensure your wallet has enough CELO tokens for deployment. Deployment typically costs around 0.01-0.05 CELO.

### Verification Failures
- Ensure your `CELOSCAN_API_KEY` is correct
- Check that the compiler version matches (0.8.19)
- Wait a few minutes and try manual verification

### RPC Connection Issues
- Try using alternative RPC endpoints
- Check your internet connection
- Verify the RPC URL is correct

## Security Reminders

- ✅ **NEVER commit your `.env` file**
- ✅ **Keep your private key secure**
- ✅ **Use a hardware wallet for mainnet deployments**
- ✅ **Test thoroughly on Alfajores before mainnet**
- ✅ **Consider using a multi-sig wallet for admin operations**

## Support

For issues or questions:
- GitHub: https://github.com/web3thunderfinance/smartcontractsandcircuits
- Email: security@web3thunderfinance.io
