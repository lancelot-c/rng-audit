## RNG Audit

This repository contains scripts enabling anyone to quickly audit the random number generator (RNG) used in the [Verifiable Draws](https://github.com/lancelot-c/verifiable-draws) project.

It is separated in 2 parts:
- [Audit of the Chainlink VRF random numbers](https://github.com/lancelot-c/rng-audit?tab=readme-ov-file#empirical-testing-on-chainlink-vrf) that Verifiable Draws uses as a source of randomness
- [Audit of the observed drawing outcomes](https://github.com/lancelot-c/rng-audit?tab=readme-ov-file#empirical-testing-on-observed-drawing-outcomes)

For each part we collect a huge sample of randomness which can then be manually analyzed by simply looking at the data and realizing that it looks random. Alternatively, you can perform a more in-depth analysis by using the collected data as inputs for the [Diehard tests](https://en.wikipedia.org/wiki/Diehard_tests) to precisely measure the quality of the random number generator.

## Setup

Clone this repository on your local machine:
```shell
git clone https://github.com/lancelot-c/rng-audit.git
```

## Empirical testing on Chainlink VRF

This is the testing of the raw randomness received from Chainlink VRF requests.

A smart contract is needed to generate VRF randomness on-demand and make it available for export.
Such a contract is available at `src/OnlyRaw.sol` and is deployed for your convenience at [0xBBCD0c8DBdC112dd29af8c57Ee8740bD9feE084B](https://sepolia.arbiscan.io/address/0xBBCD0c8DBdC112dd29af8c57Ee8740bD9feE084B#code). The variable [wordsCounter](https://sepolia.arbiscan.io/address/0xbbcd0c8dbdc112dd29af8c57ee8740bd9fee084b#readContract#F4) is the number of random values that the contract has already generated. At the time of writing, the contract holds a total of 1,500,000 random words, which we consider enough to perform a relevant analysis.

### [Optional] - Generate additional VRF randomness

If you need more randomness, the easiest way is to [registrer a time-based Upkeep](https://automation.chain.link/arbitrum-sepolia) for this contract on the function `makeVrfRequest(110)` with the CRON expression `*/1 * * * *` for an execution every minute. Make sure [the VRF subscription](https://vrf.chain.link/arbitrum-sepolia/88) for this contract is sufficiently funded, otherwise add funds to the subscription with your own wallet: `Connect Wallet > Actions dropdown > Fund subscription`.

ℹ️ Even though Chainlink says you can generate a maximum number of 500 random words per VRF request, it turns out in practice that 110 is the maximum you can ask for (at least on Arbitrum Sepolia), any value greater than that will return an error.

### Export the VRF randomness

Now we want to export all this raw randomness out of the smart contract.

The `OnlyRaw` script is doing precisely that:
```shell
cd scripts/OnlyRaw
```

Set the variables in the `.env` depending on what values you want to export, for example if you want the first 1,000,000 values:
```shell
START_AT=1
HOW_MANY=1000000
```

Then run the script:
```shell
npm install
node OnlyRaw.js
```

The output file is located at `script-outputs/OnlyRaw-<START_AT>-<HOW_MANY>.txt`.

If you need additionnal values, let's say 5,000,000 more values, you can run the same script again but this time by ignoring the values that you've already exported:
```shell
START_AT=1000001
HOW_MANY=5000000
```

ℹ️ Verifiable Draws is using 64-bit numbers as a source of randomness, however each random word received from Chainlink is 256-bit so each random word is splitted into 4 numbers of 64-bit each and these 64-bit numbers are the ones being exported. This means that when you are exporting 1,000,000 values with this script, you are actually only exporting 250,000 random words from Chainlink. It is important to know this when setting the value for the `HOW_MANY` variable. The maximum value of `HOW_MANY` is therefore the value of [wordsCounter](https://sepolia.arbiscan.io/address/0xbbcd0c8dbdc112dd29af8c57ee8740bd9fee084b#readContract#F4) multiplied by 4.

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


To install Foundry run the following command in your terminal, then follow the onscreen instructions.
```shell
curl -L https://foundry.paradigm.xyz | bash
```

Install the project dependencies:
```shell
cd rng-audit
forge install lancelot-c/verifiable-draws
forge install smartcontractkit/chainlink
forge install OpenZeppelin/openzeppelin-contracts
```

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
