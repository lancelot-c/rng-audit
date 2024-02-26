## RNG Audit

**Data collection tool for Verifiable Draws using [Foundry](https://github.com/foundry-rs/foundry).**

The collected randomness in then passed in [Diehard tests](https://en.wikipedia.org/wiki/Diehard_tests) for measuring the quality of the random number generator.

## Setup
Install dependencies:
```shell
$ forge install lancelot-c/verifiable-draws
$ forge install OpenZeppelin/openzeppelin-contracts
```


## Empirical testing on raw output of the RNG

This is the testing of the random output received from Chainlink VRF.

In order to gather enough data, we would like to collect 12.5 million values of 64-bit each. This can be achieved by triggering 6250 VRF requests because a single request can deliver up to 500 random values of 256-bit each (= 4 * 64-bit), and 6250 * 500 * 4 = 12.5 million


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

This is roughly 32 billion samples total. Now, this is quite a lot of data to collect so instead of using Chainlink VRF we can precompute random values beforehand in `/rng-inputs` and use them as a source of randomness to generate drawing outcomes.

Make sure you have an `.env` with the desired data set parameters:
```
RANGE=
POSITIONS=
DRAWS=
```

Then run:
```shell
$ forge script script/OnlyOutcomes.s.sol:OnlyOutcomesScript --memory-limit 500000000
```

Increase `--memory-limit` in case you encounteer a `MemoryLimitOOG` error

### Parallelization

Each data set can run in parallel if you launch several instances of this script on different machines with different `.env` values
