// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.23;

import {Script, console} from "forge-std/Script.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OnlyOutcomesScript is Script {

    uint32 private entropyNeededPerWinner = 8; // Retrieving 8 bytes (64 bits) of entropy for each winner is enough to have an infinitely small scaling bias

    // Simulate the checkDrawWinners() function of VerifiableDraws.sol
    function run() public {

        // Get dataset parameters from .env
        uint32 range = uint32(vm.envUint("RANGE"));
        uint32 positions = uint32(vm.envUint("POSITIONS"));
        uint32 draws = uint32(vm.envUint("DRAWS"));

        // RNG files can be downloaded here: https://www.rngresearch.com/download/
        string memory rngPath = "rng-inputs/block0.rng";
        bytes memory totalEntropy = vm.readFileBinary(rngPath);

        uint32 nbWinners = positions;
        uint32 nbParticipants = range;
        uint32 entropyNeededPerDraw = computeEntropyNeeded(nbWinners);
        uint32 totalEntropyNeeded = entropyNeededPerDraw * draws;

        require(totalEntropyNeeded <= totalEntropy.length, "Not enough RNG data to perform the test");

        string memory outputPath = string.concat("script-outputs/OnlyOutcomes-", Strings.toString(range), "-", Strings.toString(positions), "-", Strings.toString(draws), ".txt");

        uint32 onePercentProgress = draws / 100;
        uint32 percentProgress = 0;

        for (uint32 d = 0; d < draws; d++) {

            // Periodically log the progression of the script
            if (d % onePercentProgress == 0) {
                console.logString(string.concat(Strings.toString(percentProgress), "% (", Strings.toString(d), "/", Strings.toString(draws), " draws)"));
                percentProgress++;
            }
            
            uint32[] memory winnerIndexes = new uint32[](nbWinners); // Fixed sized array, all elements initialize to 0
            
            bytes memory simulatedChainlinkResponse = extractBytes(totalEntropy, d * entropyNeededPerDraw, entropyNeededPerDraw);

            for (uint32 i = 0; i < nbWinners; i++) {

                uint64 extractedEntropy = uint64(extractBytes8(simulatedChainlinkResponse, i * entropyNeededPerWinner));

                // When i winners are already selected, we only need a random number between 0 and nbParticipants - i - 1 to select the next winner.
                // ⚠️ Using 64-bit integers for the modulo operation is extremely important to prevent scaling bias ⚠️
                // Then it is fine to convert the result to a 32-bit integer because we know that the output of the modulo will always be stricly less than nbParticipants which is a 32-bit integer
                uint32 randomNumber = uint32(extractedEntropy % uint64(nbParticipants - i));
                uint32 nextWinningIndex = randomNumber;
                uint32 min = 0;

                // Once a participant has been selected as a winner, it can never be selected again for that draw.
                // We enforce that by looping over all participants and ignoring those who are already known winners.
                // The offset variable keeps track of how many participants are ignored as we loop through the list and increments the next winning index accordingly.
                // When there is no more participants to ignore (offset == 0), it means we have reached the proper winning index so we break the loop and save this index.
                while (true) {
                    uint32 offset = nbValuesBetween(winnerIndexes, min, nextWinningIndex, i);
                    if (offset == 0) {
                        break;
                    }
                    min = nextWinningIndex + 1;
                    nextWinningIndex += offset;
                }

                winnerIndexes[i] = nextWinningIndex;
            }

            string memory winnerIndexesString = "";

            // We want to display line numbers, not indexes, so all indexes need to be +1
            for (uint32 i = 0; i < nbWinners; i++) {
                winnerIndexes[i] += 1;
                winnerIndexesString = string.concat(winnerIndexesString, Strings.toString(winnerIndexes[i]), " ");
            }

            vm.writeLine(outputPath, winnerIndexesString);
        }

        console.logString(string.concat("Output file: ", outputPath));
    }

    function computeEntropyNeeded(uint32 nbWinners) private view returns (uint32) {
        return nbWinners * entropyNeededPerWinner;
    }

    function extractBytes(bytes memory data, uint32 from, uint32 n) private pure returns (bytes memory) {
        
        require(data.length >= from + n, "Slice out of bounds");
        
        bytes memory returnValue = new bytes(n);
        for (uint32 i = 0; i < n; i++) {
            returnValue[i] = data[from + i]; 
        }
        return returnValue;
    }

    function extractBytes8(bytes memory data, uint32 from) private pure returns (bytes8) {
        
        require(data.length >= from + 8, "Slice out of bounds");

        return bytes8(bytes.concat(data[from + 0], data[from + 1], data[from + 2], data[from + 3], data[from + 4], data[from + 5], data[from + 6], data[from + 7]));
    }

    function nbValuesBetween(uint32[] memory arr, uint32 min, uint32 max, uint32 imax) internal pure returns (uint32) {
        uint32 count = 0;

        for (uint32 i = 0; i < imax; i++) {
            if (arr[i] >= min && arr[i] <= max) {
                count++;
            }
        }

        return count;
    }

}
