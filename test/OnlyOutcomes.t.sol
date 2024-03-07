// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.23;

import {Test, console} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OnlyOutcomes is Test {
    uint32 range;
    uint32 positions;
    uint32 draws;
    uint32 nbWinners;
    uint32 nbParticipants;
    string outputPath;

    function setUp() public {
        // Get dataset parameters from .env
        range = uint32(vm.envUint("RANGE"));
        positions = uint32(vm.envUint("POSITIONS"));
        draws = uint32(vm.envUint("FOUNDRY_FUZZ_RUNS"));

        nbWinners = positions;
        nbParticipants = range;

        outputPath = string.concat(
            "script-outputs/OnlyOutcomes-",
            Strings.toString(range),
            "-",
            Strings.toString(positions),
            "-",
            Strings.toString(draws),
            ".txt"
        );
    }

    // Simulate the checkDrawWinners function of VerifiableDraws.sol
    // Forge generates a new value for "entropy" every time this function is called, this is called Fuzz Testing
    // See https://book.getfoundry.sh/forge/fuzz-testing
    function testFuzz_checkDrawWinners(bytes32 entropy) public {
        bytes32 newEntropy;
        uint32 exported = 0;

        uint32[] memory winnerIndexes = new uint32[](nbWinners); // Fixed sized array, all elements initialize to 0

        for (uint32 i = 0; i < nbWinners; i++) {
            uint32 modulo = exported % 4;

            // A single value of keccak256 can be used for 4 winners (4 * 64 bits = 256 bits) so we only run keccak256 every 4 winners
            if (modulo == 0) {
                newEntropy = keccak256(abi.encodePacked(entropy, i));
            }

            bytes8 extractedEntropy = extractBytes8(newEntropy, 8 * modulo);

            // When i winners are already selected, we only need a random number between 0 and nbParticipants - i - 1 to select the next winner.
            // ⚠️ Using 64-bit integers for the modulo operation is extremely important to prevent scaling bias ⚠️
            // Then it is fine to convert the result to a 32-bit integer because we know that the output of the modulo will always be stricly less than nbParticipants which is a 32-bit integer
            uint32 randomNumber = uint32(uint64(extractedEntropy) % uint64(nbParticipants - i));
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
            exported++;
        }

        string memory winnerIndexesString = "";

        // We want to display line numbers, not indexes, so all indexes need to be +1
        for (uint32 i = 0; i < nbWinners; i++) {
            winnerIndexes[i] += 1;
            winnerIndexesString = string.concat(winnerIndexesString, Strings.toString(winnerIndexes[i]));

            // Prevent the line to end with a space
            if (i != nbWinners - 1) {
                winnerIndexesString = string.concat(winnerIndexesString, " ");
            }
        }

        vm.writeLine(outputPath, winnerIndexesString);

        console.logString(string.concat("Output file: ", outputPath));
    }

    function extractBytes8(bytes32 data, uint32 from) private pure returns (bytes8) {
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
