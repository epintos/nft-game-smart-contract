## NFT Game Solidity Smart Contract

This is a practice project where I explore and experiment with various Solidity concepts. The idea is inspired by an older project on [buildspace](https://buildspace.so/).

Developed a smart contract to simulate a basic game using NFTs.
- User can mint certain characters with abilities.
- User can attack a boss. The boss is unique and doesn't revive (for now).
- The attack damage is calculated randomly using Chainlink VRF.

Known issues:
- Chainlink subscription creation in Anvil fails unless `blockhash(block.number + 1)` is updated in the `createSubscription` method in `SubscriptionAPI` mock contract.
- Build fails with `Stack too deep.` Adding `via_ir = true` to Foundry fixes the issue for now.

## Usage

### Install

```shell
$ make install
```

### Test

```shell
$ make test
```

### Deploy

```shell
$ make deploy-anvil
```

```shell
$ make deploy-sepolia
```

### Fund metamask or others

```shell
$ make fund-account
```

### Interactions

Mint:
```shell
$ make mint-nft CHARACTER_INDEX=0
```

Attack:
```shell
$ make attack TOKEN_ID=0
```
