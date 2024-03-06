/* DEPRECATED
 * This script is too slow for practical use because of the collectedEntropy call at line 41 being too slow
 * Please use "node OnlyRaw.js" in the OnlyRaw folder instead
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {OnlyRaw} from "src/OnlyRaw.sol";

contract OnlyRawScript is Script {
    OnlyRaw public onlyRawContract;
    uint32 private entropyNeededPerWinner = 8; // Retrieving 8 bytes (64 bits) of entropy for each winner is enough to have an infinitely small scaling bias
    uint32 private bytesPerWord = 32; // Each random word from Chainlink VRF gives an entropy of 32 bytes
    uint32 private wordsPerRequest = 110;
    uint32 private nbWinnersPerRequest = (bytesPerWord / entropyNeededPerWinner) * wordsPerRequest; // = 440

    function run() public {
        // Get parameters from .env
        uint32 start_at = uint32(vm.envUint("RAW_64B_START_AT")); // min value: 1
        uint32 vrfRequestNb = divisionRoundUp(start_at, nbWinnersPerRequest);
        uint32 how_many = uint32(vm.envUint("RAW_64B_HOW_MANY")); // min value: 1
        uint32 exported = 0;
        string memory outputPath = string.concat(
            "script-outputs/OnlyRaw-", Strings.toString(start_at), "-", Strings.toString(how_many), ".txt"
        );

        address contractAddress = vm.envAddress("ONLY_RAW_CONTRACT_ADDRESS");
        onlyRawContract = OnlyRaw(contractAddress);

        uint32 progress = 0;
        bytes memory rawEntropy = "0x";

        while (exported < how_many) {
            // This call is extremely slow (≈20sec), it seems to be a Forge bug as the same call using the "cast" command is blazing fast (≈1sec)
            // Try running "cast call <ONLY_RAW_CONTRACT_ADDRESS> "collectedEntropy(uint32)(bytes)" 1 --rpc-url https://sepolia-rollup.arbitrum.io/rpc" and see for yourself
            // This unfortunately makes this whole script too slow for practical use, it seems better to use Node.js instead
            rawEntropy = onlyRawContract.collectedEntropy(vrfRequestNb);

            for (uint32 j = 0; j < nbWinnersPerRequest; j++) {
                if (exported < how_many) {
                    vm.writeLine(outputPath, Strings.toString(uint64(extractBytes8(rawEntropy, j * 8))));
                } else {
                    break;
                }

                exported++;
            }

            vrfRequestNb++;
        }

        console.logString(string.concat("Output file: ", outputPath));
    }

    function extractBytes8(bytes memory data, uint32 from) private pure returns (bytes8) {
        require(data.length >= from + 8, "Slice out of bounds");

        return bytes8(
            bytes.concat(
                data[from + 0],
                data[from + 1],
                data[from + 2],
                data[from + 3],
                data[from + 4],
                data[from + 5],
                data[from + 6],
                data[from + 7]
            )
        );
    }

    // Division rounds down by default in Solidity, this function rounds up
    function divisionRoundUp(uint32 a, uint32 m) private pure returns (uint32) {
        return (a + m - 1) / m;
    }
}
