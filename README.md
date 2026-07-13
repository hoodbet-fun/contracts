# hoodbet.fun contracts

Custom HoodBet contracts for Robinhood Chain (4663): fee harvester, RNG adapter, HoodPoints registry.

## Setup

```bash
forge install
forge test
```

## Deploy

See [hoodbet docs](https://github.com/hoodbet-fun/hoodbet/blob/main/docs/DEPLOY_MAINNET.md).

```bash
export SAFE_OWNER=0x5FF989aCB81e612fb54d2BDE9C6334B4C9a8f117
export PRIZE_POOL=<deployed>
forge script script/DeployCore.s.sol --rpc-url https://rpc.mainnet.chain.robinhood.com --broadcast
```
