# Web3 Thunder Finance – Mixer & Yield Protocol

An EVM-compatible privacy-focused mixer that deploys pooled deposits into external lending markets (e.g. Aave) to earn real yield.
Users deposit supported ERC20 stablecoins through commitment-based privacy, accrue yield while funds are pooled, and later withdraw
principal + proportional yield using a secret (commitment/nullifier) flow.

---

## ⚠️ Status & Scope

This repository now pivots from a role-based lending coordination contract to a **Yield Mixer** prototype. The current implementation provides scaffolding for: deposits, commitment tracking, nullifier-based withdrawals, and hooks to integrate Aave V3. Full production-grade privacy (ZK proof verification, Merkle trees, relayer incentivization) is not yet implemented. Treat this code as experimental.

## ✨ Core Design

- **Privacy Primitive (Commitment)**: Users submit a precomputed `bytes32 commitment` at deposit; no address stored in mapping under that key, aiming to break direct linkage. (Current prototype still leaks timing & gas heuristics; real privacy requires relayers + batching + proof verification.)
- **Yield Accrual**: Deposits are forwarded to a configured Aave Pool. The protocol tracks total principal vs current aToken balance to determine aggregate yield.
- **Proportional Distribution**: On withdrawal, the user proves ownership of a commitment (stubbed) and receives principal + pro-rata share of accumulated yield since deposit.
- **Nullifier Set**: Prevents double-withdraws by marking a unique nullifier derived from the secret.
- **Admin Controls**: Admin can pause, set pool/token addresses, and emergency-withdraw in catastrophic scenarios.

## 🔐 Security & Risk Considerations

| Area | Notes |
|------|-------|
| Privacy | No ZK proof / Merkle inclusion check yet. Add Tornado-style tree + SNARK verifier before mainnet. |
| Yield Source | External protocol risk (smart contract risk on Aave, liquidation, rate volatility). |
| Regulatory | Mixers may face compliance scrutiny. Consider geo-fencing, chain analytics, opt-in transparency. |
| Fee-on-Transfer Tokens | Not supported. Assumes 1:1 transfer semantics. |
| Reentrancy | Guarded on state-changing external flows. |
| Oracle / Pricing | Not required for base stablecoin yield; avoid adding price dependencies prematurely. |
| Slippage | Lending supply not subject to AMM slippage; withdraw may depend on liquidity availability. |

## 🧱 Contracts Overview

| Contract | Purpose |
|----------|---------|
| `Web3ThunderFinanceMixer.sol` | Main protocol: deposits, yield accounting, withdrawals. |
| `IAavePool.sol` | Minimal interface for Aave V3 pool integration. |

## 🛠 Roadmap (High-Level)

1. Merkle tree state (incremental tree on-chain or off-chain + root updates).
2. Zero-Knowledge proof verification (e.g., Groth16) for unlinkable withdrawal.
3. Relayer fee mechanism & reward accounting.
4. Multi-token support with isolated accounting per asset.
5. Gas optimizations (struct packing, assembly for hashing, events indexing).
6. Formal invariant tests (principal sum == tracked aToken underlying minus yield allocations).

## 🚀 Quick Start (Foundry)

### Build

```bash
forge build
```

### Test

```bash
forge test
```

### Local Network

```bash
anvil
```

### Deploy Mixer (Example)

```bash
forge script script/DeployWeb3ThunderFinanceMixer.s.sol:DeployWeb3ThunderFinanceMixer \
  --rpc-url $RPC_URL \
  --broadcast \
  --verify
```

Environment variables expected: `PRIVATE_KEY`, `POOL_ADDRESS`, `TOKEN_ADDRESS`, `ATOKEN_ADDRESS`.

### Gas Snapshot

```bash
forge snapshot
```

### Formatting

```bash
forge fmt
```

### Cast Utilities

```bash
cast <subcommand>
```

## 📝 NatSpec Conventions

All external/public functions include:
- `@notice` high-level description
- `@dev` lower-level details & assumptions
- `@param` / `@return` tags
- Custom errors prefixed logically (`CommitmentUsed`, `InvalidCommitment`, `AlreadyWithdrawn` etc.)

## 📂 Directory Structure (Relevant Excerpts)

```text
src/
  Web3ThunderFinanceMixer.sol     # Mixer + yield contract (scaffold)
  interfaces/IAavePool.sol        # Aave pool interface
script/
  DeployWeb3ThunderFinanceMixer.s.sol  # Deployment script
test/
  Web3ThunderFinanceMixer.t.sol        # Mixer tests
```

## ⚙️ Configuration Notes

Set addresses post-deploy or constructor args for:

- Lending pool (`IPool`)
- Underlying token (e.g., USDC)
- aToken representing supplied balance

Contract assumes **no rebasing** beyond interest accrual at aToken level; yield = `aTokenBalance - totalPrincipal`.

## 🔄 Withdrawal Flow (Planned)

1. User holds secret `s` and commits: `commit = keccak256(abi.encodePacked(s, amount))` off-chain.
2. User calls `deposit(commit, amount)` transferring tokens.
3. After delay/yield accrual, user derives `nullifier = keccak256(abi.encodePacked(s))`.
4. Provides proof (future ZK) + nullifier to `withdraw`.
5. Contract validates unused nullifier, marks as spent, transfers principal+yield share.

Prototype currently omits step 4 proof verification (stubbed). Do **NOT** rely on anonymity claims yet.

## 🧪 Testing Strategy (Upcoming)

- Unit tests for deposit/withdraw accounting.
- Fuzz tests: random deposit sizes & timing.
- Invariant: sum(principal) <= aTokenBalance.
- Reentrancy tests with malicious token mocks.

## 📜 License

SPDX-License-Identifier: MIT

## 📚 Foundry Reference

See: [Foundry Book](https://book.getfoundry.sh/)

## 🤝 Security Contact

[security@web3thunderfinance.io](mailto:security@web3thunderfinance.io)

---
 
### Help

```bash
forge --help
anvil --help
cast --help
```
