## RNG Audit

**Randomness collection tool for [Verifiable Draws](https://github.com/lancelot-c/verifiable-draws) using [Foundry](https://github.com/foundry-rs/foundry).**

Once you have collected the randomness with this tool, you can then perform any kind of tests on it such as [Diehard tests](https://en.wikipedia.org/wiki/Diehard_tests) to measure the quality of the random number generator.

If you trust us and you simply want to download the randomness collections that we have generated with this tool you can find them in the `script-outputs` folder. Otherwise, running this tool will enable you to generate your own randomness collections.

## Setup

Clone this repository on your local machine:
```shell
git clone https://github.com/lancelot-c/rng-audit.git
```

To install Foundry run the following command in your terminal, then follow the onscreen instructions.
```shell
curl -L https://foundry.paradigm.xyz | bash
```

Install the project dependencies:
```shell
cd rng-audit
forge install lancelot-c/verifiable-draws
forge install OpenZeppelin/openzeppelin-contracts
forge install smartcontractkit/chainlink
```


## Empirical testing on raw output of the RNG

This is the testing of the random output received from Chainlink VRF.

In order to gather enough data, we would like to collect 12.5 million values of 64-bit each. This can be achieved by triggering 6250 VRF requests because a single request can deliver up to 500 random values of 256-bit each (= 4 * 64-bit), and 6250 * 500 * 4 = 12.5 million

### Fund the VRF subscription

You will need a smart contract whose sole purpose is to trigger VRF requests on-demand and aggregate the resulting raw randomness.
Thus a contract is available at `src/OnlyRaw.sol` and is deployed for your convenience at [0x1c6d4FdA85e25f1A3C8459191c40221BBe777C6b](https://sepolia.arbiscan.io/address/0x1c6d4FdA85e25f1A3C8459191c40221BBe777C6b#code).

Make sure the balance of [its VRF subscription](https://vrf.chain.link/arbitrum-sepolia/88) is greater than 0 LINK, otherwise you will need to add funds to the subscription with your own wallet: `Connect Wallet > Actions dropdown > Fund subscription`.

ℹ️ At the time of writing, a single full VRF request costs on average 0.02 LINK. Fund the subscription depending on how much testing you want to perform.

## Empirical testing on observed drawing outcomes

We would like to collect the following 20 data sets:

| **Range** | **Positions** | **Replacement** | **Draws**      |
|-----------|---------------|-----------------|----------------|
| 2         | 1             | N/A             |      1,000,000 |
| 17        | 5             | No              |    20,000,000  |
| 31        | 12            | No              |    50,000,000  |
| 57        | 20            | No              |    50,000,000  |
| 105       | 7             | No              |   100,000,000  |
| 194       | 30            | No              |   100,000,000  |
| 358       | 20            | No              |   100,000,000  |
| 660       | 40            | No              |    50,000,000  |
| 1,217     | 50            | No              |    50,000,000  |
| 2,243     | 10            | No              |   200,000,000  |
| 4,135     | 12            | No              |   200,000,000  |
| 7,622     | 4             | No              |   500,000,000  |
| 14,050    | 9             | No              |   200,000,000  |
| 25,899    | 75            | No              |    20,000,000  |
| 47,742    | 10            | No              |   200,000,000  |
| 65,536    | 5             | No              |   500,000,000  |
| 72,859    | 10            | No              |   200,000,000  |
| 80,989    | 25            | No              |    50,000,000  |
| 90,007    | 15            | No              |   100,000,000  |
| 100,000   | 100           | No              |    10,000,000  |

This is roughly 32 billion samples total. Now, this is quite a lot of data to collect so instead of using Chainlink VRF we precompute random values beforehand in `/rng-inputs/*.rng` and use them as a source of randomness to generate drawing outcomes. We are using the `.rng` files provided by [rngresearch.com](https://www.rngresearch.com/download/) but you can replace them with your own if you prefer.

Make sure you have an `.env` at the root of the project with the desired data set parameters, for example if you want to collect dataset #2 your `.env` file should look like this:
```
RANGE=17
POSITIONS=5
DRAWS=20000000
```

Then run:
```shell
forge script script/OnlyOutcomes.s.sol:OnlyOutcomesScript --memory-limit 500000000
```

Increase `--memory-limit` in case you encounteer a `MemoryLimitOOG` error

### Parallelization

For faster execution, each data set can run in parallel if you launch several instances of this script on different machines with different `.env` values.


## Getting Help

Our [Discord](https://discord.gg/UTcNWAZ9) is the best place to ask for help.
