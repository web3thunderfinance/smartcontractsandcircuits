# Etherscan v2 API Configuration for CeloScan

This document explains the Etherscan v2 API configuration used for verifying smart contracts on CeloScan.

## Configuration Overview

The `foundry.toml` file has been configured with Etherscan v2 API settings that allow seamless contract verification on both Celo Alfajores testnet and Celo mainnet.

## Configuration Details

### Chain Aliases

Two custom chain aliases are defined:

1. **`alfajores`** - Celo Alfajores Testnet
   - Chain ID: 44787
   - API URL: `https://api-alfajores.celoscan.io/api`
   - Uses `CELOSCAN_API_KEY` from environment

2. **`celo`** - Celo Mainnet
   - Chain ID: 42220
   - API URL: `https://api.celoscan.io/api`
   - Uses `CELOSCAN_API_KEY` from environment

### RPC Endpoints

Corresponding RPC endpoints are configured:
- **alfajores**: Uses `CELO_ALFAJORES_RPC_URL` from environment
- **celo**: Uses `CELO_RPC_URL` from environment

## Usage

### Deployment with Automatic Verification

**Testnet:**
```bash
forge script script/DeployWeb3ThunderFinanceToCelo.s.sol:DeployWeb3ThunderFinanceToCelo \
  --rpc-url alfajores \
  --broadcast \
  --verify \
  --etherscan-api-key $CELOSCAN_API_KEY \
  -vvvv
```

**Mainnet:**
```bash
forge script script/DeployWeb3ThunderFinanceToCelo.s.sol:DeployWeb3ThunderFinanceToCelo \
  --rpc-url celo \
  --broadcast \
  --verify \
  --etherscan-api-key $CELOSCAN_API_KEY \
  -vvvv
```

### Manual Verification

If automatic verification fails, verify manually:

**Testnet:**
```bash
forge verify-contract \
  --rpc-url alfajores \
  --etherscan-api-key $CELOSCAN_API_KEY \
  --watch \
  <CONTRACT_ADDRESS> \
  src/Web3ThunderFinanceProtocol.sol:Web3ThunderFinanceProtocol
```

**Mainnet:**
```bash
forge verify-contract \
  --rpc-url celo \
  --etherscan-api-key $CELOSCAN_API_KEY \
  --watch \
  <CONTRACT_ADDRESS> \
  src/Web3ThunderFinanceProtocol.sol:Web3ThunderFinanceProtocol
```

## How It Works

1. **Chain Alias Resolution**: When you use `--rpc-url alfajores` or `--rpc-url celo`, Foundry looks up the corresponding configuration in `foundry.toml`

2. **Automatic Settings**: The configuration automatically provides:
   - Correct Chain ID
   - CeloScan API endpoint
   - API key from environment variable
   - Compiler settings (Solidity 0.8.19, 200 optimizer runs)

3. **Etherscan v2 Compatibility**: CeloScan uses Etherscan v2 API, which is fully compatible with Foundry's verification system

## Benefits

✅ **Simplified Commands**: No need to specify chain IDs or API URLs manually
✅ **Environment Variables**: API keys are securely loaded from `.env`
✅ **Consistent Settings**: All verification attempts use the same compiler settings
✅ **Reusable Configuration**: Same setup works for deployment and verification

## Troubleshooting

### Verification Pending
If verification shows as "pending", wait a few minutes and check CeloScan. The blockchain may need time to index the contract.

### Wrong Chain ID Error
Ensure you're using the correct alias (`alfajores` or `celo`) and that your `.env` file has the correct RPC URLs.

### API Key Invalid
1. Verify your CeloScan API key at https://celoscan.io/myapikey
2. Ensure `.env` file has the correct `CELOSCAN_API_KEY`
3. Reload environment: `source .env`

### Compiler Mismatch
The configuration uses Solidity 0.8.19 with 200 optimizer runs. Ensure your contract was compiled with these exact settings.

## References

- [Foundry Verification Documentation](https://book.getfoundry.sh/reference/forge/forge-verify-contract)
- [CeloScan](https://celoscan.io)
- [CeloScan Alfajores](https://alfajores.celoscan.io)
- [Celo Documentation](https://docs.celo.org)
